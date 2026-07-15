# Generic-rules carryover (Pharo-inspired) — execution plan

**STATUS: EXECUTED 2026-07-15 — Phases 1–6 complete. Current state lives in
`docs/lint-and-static-checks.md` (gates §3, the severity policy §3b, the censuses §3c); the findings
live in the gitignored ledger `duplication-report/triage-report.md` (ROUND 4 / 4b). This file keeps
only the execution record + the §8 DEFERRED backlog.**

**Outcome vs. plan.** Phase 1 landed GREEN on day one exactly as §1.1 predicted — 7046 calls checked,
0 unresolved, ~0.1 s; the probe's 21 false positives collapsed to precisely §1.5's 9 vendor seeds once
§1.2's def-forms were harvested. Phase 2 seeded 7 stinks at MEASURED baselines (36/89/10/19/**3**/5/105
— `timer` measured 3, not the estimated 5). Phase 3: 10 IDENTICAL-TO-INHERITED, 0 SHADOWS-MIXIN, 0
JUST-SENDS-SUPER. Phase 4: 10 PULL-UP (7 same-default), 37 DEMOTE (+49 withheld). Zero `src/` edits, as
contracted.

**Four deviations from this plan, each evidence-driven (details in the gate/census headers):**
1. **§1.4 regex-literal masking: NOT implemented, and not needed.** The one probe artifact it was for
   (`.times(` inside a regex literal) resolves for real — `Number::times` is defined at
   `src/boot/numbertimes.coffee:44` — once §1.2's prototype-extension form is harvested. Measured: zero
   call-shaped tokens hide in a block regex. Adding regex-vs-division guesswork for no gain was rejected.
2. **§1.2/§1.4 masking is ASYMMETRIC** (the plan implied one masker): defs use a naive strings-KEEPING
   strip, calls use the `stripLine`-grade one. Load-bearing — `TRIPLE_QUOTES = ///'''///`
   (`dependencies-finding.coffee:59`) puts `stripLine` into a bogus heredoc state that blanks that file's
   tail; blanked DEFS would cause false POSITIVES, blanked CALLS only cost coverage.
3. **§3/§4 reuse over copying.** Rather than copy the census's parse phase, `runCensus()` now EXPORTS the
   class model (`classInfo`/`chainOf`/`resolve`) + `maskLine` (hoisted to module scope). Proven neutral:
   the `--full` census output is byte-identical to HEAD's, and the [S]/[U] gate is unmoved.
4. **§4.3's DEMOTE spec had a hole; a third exclusion was added.** It counts only `@prop` self-references,
   so it called 22 `PreferencesAndSettings` fields demotable when they are the global settings surface read
   as `WorldWdgt.preferencesAndSettings.<field>`. A `.name` member-read veto closes it (86→37; withheld
   count printed).

**Two false positives the mandated spot-checks caught in the censuses themselves** — both now permanent
soundness rules: a method's SIGNATURE must be compared, not just its body (`(@color) -> super` is NOT
removable — `VideoPlayCreatorButtonWdgt`); and a use outside any method body (a multi-line ctor param
list) makes the property public API (`ListWdgt.elements`). A third — `InspectorWdgt.textWidget`, which
hand-verification wrongly cleared — was caught only by the automated `.name` veto (`MacroToolkit.coffee:879`
reads it). Recorded in the ledger: hand spot-checking is not a substitute for the exclusions.

**Closed straight after the arc commit (owner decisions, 2026-07-15):**
- **§8.6 console.log — RESOLVED: accept as-is.** The premise did not survive measurement: 201 of 224 sites
  are behind explicit debug flags and the other 23 are all guards/audits/Automator-paths/error-handlers, so
  nothing logs in normal operation; `drop_console` would have stripped the error diagnostics we want. The
  one real finding inside it — 6 genuine error paths using the wrong verb — was fixed (`console.log` →
  `console.error`, making them visible to the gates that key off `console.error`). Full detail in §8.6.
- **Both tightenable ratchets closed:** the stale `rotateZ` dead-method entry deleted (`Point3D.coffee` has
  `rotateX`/`rotateY` but no `rotateZ` — the method does not exist, so the entry could never match), and
  `BASELINE_U_QUERY` tightened 150 → 148 to lock a gain a previous arc had already banked.

**Still banked, NOT done (owner-gated):** everything else in §8 below.

---

**Original plan follows (as authored 2026-07-15, before execution).**
**Owner decisions already taken (2026-07-15):** the unresolved-sends gate (Phase 1) gates the build
IMMEDIATELY (no advisory soak); the hierarchy-duplication and property-placement advisories
(Phases 3–4) are wanted NOW, not parked; `console.log` is NOT in scope as a stink (but see the
verified finding in §8.6 — it is *not* stripped from production builds, contrary to prior belief).

This plan is written to be executed **cold, by an LLM with zero prior context**. Everything needed
is embedded or pointed at by absolute path. Read §0 before touching anything.

---

## 0. Cold-start orientation

### 0.1 Workspace layout & discipline (non-negotiable)

- The umbrella `/Users/davidedellacasa/code/Fizzygum-all/` is **NOT a git repo**. It holds three
  independent sibling repos: `Fizzygum/` (framework source — the ONLY repo this plan commits to),
  `Fizzygum-tests/` (SystemTest suite + harness), `Fizzygum-builds/` (generated output — never edit,
  never grep from the workspace root: `latest/` is ~1.3 GB).
- Use **absolute paths everywhere**; the shell's cwd is unreliable across tool calls. Invoke the
  workflow wrapper as `/Users/davidedellacasa/code/Fizzygum-all/fg <cmd>` (never `./fg`). `fg` is
  **local workspace tooling, not committed to any repo** — editing it (Phase 5) produces no git diff
  anywhere.
- Long runs (`fg gauntlet` ~4.5–5 min, `fg presuite` ~3.5 min): launch ONCE with the Bash tool's
  `run_in_background: true`, redirect to a log, and read `/tmp/fg-<cmd>.verdict` (written `RUNNING…`
  at start, `<CMD> EXIT=<rc> …` at end). Never foreground-poll with sleep loops (a guard hook blocks
  them). Never pipe an fg call through `| tail`/`| grep` when its exit code gates a decision.
- Ad-hoc Node probes go under `Fizzygum-tests/.scratch/` (gitignored), NOT a session scratchpad —
  Node resolves `require()` from the script's directory.
- **Never commit or push autonomously.** At end of arc: present a summary + proposed commit message
  and WAIT for explicit owner approval. (Backticks corrupt commit messages through the Bash tool —
  use `git commit -F <file>`.)
- One-command re-orientation any time: `/Users/davidedellacasa/code/Fizzygum-all/fg status`.

### 0.2 What already exists (the system this plan extends)

Fizzygum has a mature build-time gate battery — **read
`/Users/davidedellacasa/code/Fizzygum-all/Fizzygum/docs/lint-and-static-checks.md` in full before
starting.** It documents: the ~14 gates wired into `build_it_please.sh`, the layering rules [A]–[U],
the exit-code convention (`0` clean / `1` violation / `2` operational error), the two ratchet idioms
(central baseline/allowlist file vs. per-method `# …-sanctioned: <reason>` marker), the
**land-it-green** discipline (triage every hit BEFORE wiring a new rule), and the **self-test**
discipline (§8 there: plant a violation in a throwaway `src/__X.coffee`, confirm the gate aborts
loudly, confirm the exemption mechanism works, delete the fixture — "a lint that can't fail is
worthless").

Key existing components this plan builds on (all under
`/Users/davidedellacasa/code/Fizzygum-all/Fizzygum/buildSystem/` unless noted):

| Component | What it is | What this plan reuses from it |
|---|---|---|
| `check-dead-methods.js` (234 ln) | Gate: a method defined in src but referenced nowhere across src + harness + macro `.js` is dead. Allowlist `dead-method-allowlist.txt` (one bare name per line, `#` comments), `--update-allowlist`, `--self-test`. | Phase 1 is its exact INVERSE (sent-but-never-defined). Mirror its structure, allowlist format, CLI flags, and its harvest machinery (`defs` map of 2-space method headers; tokenizing reference harvest). |
| `check-stinks.js` (68 ln) | Gate: generic count-ratchet engine — each stink is `{id, baseline, why, re}`, build fails when count EXCEEDS baseline, prints a "tighten" note when below. **`STINKS = []` is currently EMPTY** (scaffolding kept ready). Scans `src/**/*.coffee`, per-line regex on `#`-comment-stripped lines (naive strip — does NOT mask strings). | Phase 2 pastes seven entries into it. No new file needed. |
| `census-public-private-calls.js` (611 ln) | Analysis engine (always exits 0): whole-system model — every class (`classInfo`: name → `{parent, mixins[], methods}`), full inheritance chain INCLUDING `@augmentWith` mixins (`chainOf`/`resolve`), per-method `@`-self call sites, effect/settle fixpoint, cross-repo reference harvest with per-char string/comment masking (`maskLine`). Exports `runCensus`, `tierOf`, `classifyOccurrence`; result carries `allMethodNames` (Set), `allMethods`, `nameOcc`. `check-call-separation.js` is a thin gate over it. | Phases 3–4 are new sibling "census" advisory scripts; reuse its class/hierarchy parsing (require it as a module where practical, else copy its parse phase — the codebase currently prefers copied scanners, see the note in §3 of lint-and-static-checks.md). |
| `check-layering.js` (837 ln) | The big layering gate. Its `stripLine` (multi-line-state comment AND string stripper) is the sophisticated masking routine, already copied verbatim into the census. | Phase 1 should use a `stripLine`-grade masker (strings MUST be masked — see §2.4). |
| `build_it_please.sh` | The build script; each gate is wired behind `if ! $noSyntaxCheck` with an explicit `$?` check and `exit 1`. Gates run in sequence ~line 255–491 (lines drift — grep for the neighbouring gate's name). | Phase 1 adds one wiring block (template in §2.7). |
| `Fizzygum-tests/scripts/` + `Automator-and-test-harness-src/` | The test repo's node scripts and the harness `.coffee` source (compiled into every non-homepage build). | Phase 1's definition/reference universe must include the harness `.coffee` (same lesson as check-dead-methods: harness code is live code). |

Gate edits are **pure tooling**: `buildSystem/*.js` is not compiled into the world, so a gate change
cannot alter behaviour or screenshots. Re-running the gate (`node ./buildSystem/check-<x>.js` from
`Fizzygum/`) is the verification; a full build re-run is only needed to prove the wiring.

### 0.3 The arc contract

- **ZERO behaviour changes.** This arc adds/edits tooling (`buildSystem/*`, `docs/*`, the local `fg`
  file) only. No `src/**/*.coffee` edits. All pre-existing smells are ratcheted at today's counts,
  never fixed here (driving counts down is a future arc). Consequence: no screenshot can change, no
  recapture can be needed, and the suite legs of the gauntlet must pass untouched.
- Single-repo commit at end of arc: everything committed lives in the `Fizzygum` repo. (`fg` edits
  are local-only, uncommitted, by design.)
- Owner working style: run the phases straight through, verifying each; ONE end-of-arc review;
  commit only after explicit approval.

### 0.4 Provenance (why these rules, in one paragraph)

This arc carries over the highest-value *generic* rules from Pharo Smalltalk's static-analysis stack
(SmallLint / Renraku / Quality Assistant, ~186 rules; reviewed 2026-07-15). Fizzygum's existing gates
are almost all *architecture-specific* (settle/layering/naming tiers); Pharo's catalogue is mostly
*generic* correctness and design rules. Fizzygum is unusually well-suited to the Smalltalk style of
whole-system, type-free, selector-set analysis because it is **image-like**: no module system, every
class a global, one class per file, ~486 files / ~54k lines / ~455 classes — a full-system model
builds in one ~1s pass. Specific ancestries: Phase 1 = `ReSentNotImplementedRule` (a call whose name
no one implements is a guaranteed runtime failure); Phase 2 = Pharo's cruft/idiom groups
(`ReCodeCruftLeftInMethodsRule` etc.) expressed in the existing stink-ratchet idiom; Phase 3 =
`ReEquivalentSuperclassMethodsRule` + `ReJustSendsSuperRule` + `ReLocalMethodsSameThanTraitRule`;
Phase 4 = `ReInstVarInSubclassesRule` + `ReVariableReferencedOnceRule`; Phase 5 = the Critic Browser
(one aggregated critique view).

---

## Phase 1 — `check-unresolved-sends.js`: the sends-not-implemented HARD GATE

**Rule:** every call-shaped reference `[@.]name(` in `src/**/*.coffee` and the harness
(`Fizzygum-tests/Automator-and-test-harness-src/**/*.coffee`) must resolve to a name that is
*defined somewhere* in the same universe, or be a known JS/DOM/vendor builtin, or be allowlisted.
A name that nobody defines is a guaranteed runtime `TypeError` on any path that reaches it —
the inverse of `check-dead-methods` (which catches defined-but-never-sent; this catches
sent-but-never-defined). **Wired into the build as a hard gate immediately** (owner decision).

### 1.1 Evidence this lands green (probe, 2026-07-15)

A throwaway probe (`/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests/.scratch/probe-sends-not-implemented.js`,
gitignored, disposable — superseded by this phase) found **21 unresolved names, every one a false
positive** of two known kinds:

1. **Definition forms the probe didn't harvest** — CoffeeScript prototype extensions and statics in
   `src/boot/extensions/`: `Number::toRadians = ->`, `CanvasRenderingContext2D::useLogicalPixelsUntilRestore = ->`,
   `CanvasRenderingContext2D::rebuildDerivedValue = (…) ->`, `Math.getRandomInt = (min, max) ->`,
   `swContextProto.useLogicalPixelsUntilRestore = ->` (a local-variable-proto assignment),
   `HTMLCanvasElement.createOfPhysicalDimensions`, `String::isLetter`/`isUnticked`/`hashCode`,
   `Number::toDegrees`, `Array::chunk`. → the real checker's def-harvest must include these forms (§1.2).
2. **Vendor/third-party APIs** with no in-repo definition: JSZip (`zip.file`, `generateAsync`),
   WebCrypto (`crypto.subtle.digest`), HTMLVideoElement (`@video.load`), the LCL event router
   (`eventRouter.emit`, `scope.addFunction`), the SWCanvas bitmap-text object (`bitmapText.loadFont`,
   `ensureMetricsBundleLoaded`), `Date::toJSON`, plus one Firefox-legacy *guarded* call
   (`element.toSource()` behind `if element.toSource` in `src/ListWdgt.coffee:19`) and one
   string-masking artifact (`".times("` inside a regex literal in `LCLCodePreprocessor.coffee:622`).
   → allowlist seeds (§1.5) + string/regex masking (§1.4).

So after §1.2–§1.5 the gate is expected to report **0 violations on day one**. If it doesn't, each
residual hit is triaged: real bug (fix is out of scope for this arc — STOP and surface to owner),
missing def-form (extend harvest), or legit vendor name (allowlist with reason).

### 1.2 Definition harvest (the "implementors" set)

Collect from every `.coffee` under `Fizzygum/src/` AND
`Fizzygum-tests/Automator-and-test-harness-src/` (skip gracefully with exit 0 + a note if the tests
repo is absent, exactly like `check-dead-methods.js` does):

| Form | Regex sketch (apply to comment/string-masked lines) |
|---|---|
| 2-space class-body method | `/^  ([A-Za-z_$][\w$]*)\s*:\s*(\([^)]*\)\s*)?[-=]>/` (this is the canonical `HEADER` used by every existing gate) |
| any-indent object-literal member fn | `/^\s*([A-Za-z_$][\w$]*)\s*:\s*(\([^)]*\)\s*)?[-=]>/` |
| prototype extension | `/^\s*[A-Za-z_$][\w$]*::([A-Za-z_$][\w$]*)\s*=/` |
| static / expando assignment | `/^\s*[A-Za-z_$][\w$.]*\.([A-Za-z_$][\w$]*)\s*=\s*(\([^)]*\)\s*)?[-=]>/` (catches `Math.getRandomInt = …`, `swContextProto.foo = …`) |
| bare local fn | `/^\s*([A-Za-z_$][\w$]*)\s*=\s*(\([^)]*\)\s*)?[-=]>/` |
| ALL other property keys | `/^\s*@?([A-Za-z_$][\w$]*)\s*[:=]/` — **over-approximate on purpose**: any key/assignment counts as a definition, because a property may hold a closure that gets called. Over-approximation trades detection strength for a zero-false-positive gate — the right trade (same philosophy as the rejected transitive-[G] closure: soundness beats reach; see `docs/lint-ratchet-static-checks-plan.md`). |

Also honour mixin-DSL bodies (`onceAddedClassProperties`) — the 2-space HEADER inside them already
matches at deeper indent via the any-indent forms above.

### 1.3 Call harvest (the "senders" set)

v1 scope: **paren-calls only** — `/[@.]([A-Za-z_$][\w$]*)\(/g` on masked lines, same two source
trees. Skip names starting with a capital (`new Foo(`-adjacent class refs are the boot dependency
finder's jurisdiction). Paren-less CoffeeScript calls (`@foo arg`) are deferred (§8.7) — too noisy
to gate on. Do NOT scan the macro test `.js` files in v1 (their template-literal bodies produce
JS-side false positives; the macro surface is already policed by layering rule [D]).

### 1.4 Masking

Use a `stripLine`-grade masker (comment AND string AND regex-literal stripping with multi-line
state) — copy it from `check-layering.js` (grep `stripLine`; it is already copied once into the
census, precedent for copying). The naive `indexOf('#')` strip is NOT enough: the probe's `.times(`
hit came from a regex literal, and CoffeeScript `#{…}` interpolation must keep its code visible
(check-dead-methods deliberately treats interpolation as code — same here).

### 1.5 Allowlists

Two lists, mirroring existing conventions:

1. **Builtins (in-file constant `BUILTINS`)** — JS/DOM/canvas standard methods. Seed from the probe
   file's list (String/Array/Object/Math/JSON/Promise/Date methods, canvas 2D context API, DOM
   events/elements, timers) and ADD: `toJSON`. Keep it a plain in-file Set with a header comment —
   it is a fact about the platform, not about Fizzygum.
2. **`buildSystem/unresolved-sends-allowlist.txt`** — vendor + genuinely-dynamic names, one per
   line, `name  # reason` format (exact same format as `public-api-allowlist.txt`). Seed:

   ```
   # JSZip (vendored)
   file            # JSZip: zip.file(...)
   generateAsync   # JSZip: zip.generateAsync(...)
   digest          # WebCrypto: crypto.subtle.digest(...)
   load            # HTMLVideoElement: @video.load()
   emit            # LCL eventRouter (fizzytiles vendored eventing)
   addFunction     # LCL scope API (fizzytiles)
   loadFont        # SWCanvas bitmapText API (vendored)
   ensureMetricsBundleLoaded  # SWCanvas bitmapText API (vendored)
   toSource        # Firefox-legacy, existence-guarded call in ListWdgt
   ```

   (Trim/extend this seed against what the first real run reports — the probe's def-harvest was
   weaker than §1.2's, so some of these may already resolve.) Support `--update-allowlist` and
   `--self-test` flags exactly like `check-dead-methods.js`.

### 1.6 Gate behaviour

Exit `0` clean / `1` any unresolved send not allowlisted / `2` operational error. Failure output:
one line per violation `src/Foo.coffee:123: @typoedName( — no definition found in src+harness;
fix the call, or add to buildSystem/unresolved-sends-allowlist.txt with a reason`. Print a NOTE for
allowlist entries that now resolve (stale entries), mirroring check-dead-methods' stale-entry notes.

### 1.7 Wiring into the build

Clone the standard wiring block into `build_it_please.sh`, placed immediately after the
check-dead-methods block (grep for `check-dead-methods` in the script; template from
lint-and-static-checks.md §8):

```sh
if ! $noSyntaxCheck ; then
  echo "checking unresolved sends ..."
  node ./buildSystem/check-unresolved-sends.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: unresolved-sends gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... unresolved sends OK"
fi
```

Like check-dead-methods, the checker itself must **self-skip (exit 0 with a loud SKIP note) when
`../Fizzygum-tests` is absent** — a tests-stripped checkout must still build.

### 1.8 Self-test (mandatory before wiring)

```sh
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum
printf 'class __X extends Widget\n  _p: ->\n    @thisMethodExistsNowhereAtAll()\n' > src/__X.coffee
node ./buildSystem/check-unresolved-sends.js   # EXPECT: 1 violation naming __X.coffee — exit 1
rm -f src/__X.coffee
node ./buildSystem/check-unresolved-sends.js   # EXPECT: 0 violations — exit 0
```

Also verify the allowlist exempts (temporarily add `thisMethodExistsNowhereAtAll # test` to the
allowlist, re-plant, expect pass, then revert both). Keep a `--self-test` flag that runs in-memory
fixtures, mirroring check-dead-methods.

### 1.9 Acceptance

- `node ./buildSystem/check-unresolved-sends.js` → 0 violations, exit 0, runtime ≲ 2 s.
- Self-test recipe above passes both directions.
- `/Users/davidedellacasa/code/Fizzygum-all/fg build` → "0 violations … done!!!" (this proves the
  wiring; `fg build` greps the build log for gate summary lines — make the checker print a one-line
  summary of the form `[unresolved-sends] OK — N calls checked, 0 unresolved` so it surfaces there;
  see the greps in the `fg_build()` function of `/Users/davidedellacasa/code/Fizzygum-all/fg`, and
  extend that local grep pattern to include `unresolved-sends]` — local edit, uncommitted).
- New §3-table row + §5-allowlist row added to `docs/lint-and-static-checks.md` (see Phase 5).

---

## Phase 2 — seed the empty `STINKS` table (ratcheted smells)

`buildSystem/check-stinks.js` currently has `const STINKS = [];`. Paste the following seven entries.
**Baselines below are placeholders from 2026-07-15 grep estimates** (measured on comment-filtered
grep, which differs slightly from the stink engine's own naive `#`-strip that does NOT mask strings)
— the procedure is: add each entry with baseline `9999`, run
`node ./buildSystem/check-stinks.js` once, **set each baseline to the exact count the engine
reports**, spot-check ~5 hits per stink to confirm the regex matches what it should, then re-run to
confirm all-OK. Do NOT edit any `src/**/*.coffee` to reduce counts in this arc.

```js
const STINKS = [
  { id: 'debugger-statement', baseline: 36 /* re-measure */, // Pharo: ReCodeCruftLeftInMethodsRule
    why: 'a debugger statement is left-in debug cruft; it hard-stops execution whenever devtools are open',
    re: /^\s*debugger\b/ },
  { id: 'undefined-literal', baseline: 89 /* re-measure */,
    why: "the codebase uses `nil` (src/boot/globalFunctions.coffee), never `undefined` — CLAUDE.md convention, until now manual-only",
    re: /\bundefined\b/ },
  { id: 'null-literal', baseline: 10 /* re-measure */,
    why: "the codebase uses `nil` (which is undefined), never `null` — JS-interop sites (JSON, DOM returns) are the tolerated tail",
    re: /\bnull\b/ },
  { id: 'wall-clock', baseline: 19 /* re-measure */,
    why: 'Date.now()/new Date() in framework code breaks event-stream determinism (see Fizzygum-tests/DETERMINISM.md; multi-click recognition keys off EVENT timestamps)',
    re: /\b(Date\.now\s*\(|new Date\s*\()/ },
  { id: 'timer', baseline: 5 /* re-measure */,
    why: 'setTimeout/setInterval diverge at dpr2 under parallel load (DETERMINISM.md bug-class B); the cycle/step machinery is the sanctioned clock',
    re: /\b(setTimeout|setInterval)\s*\(/ },
  { id: 'math-random', baseline: 5 /* re-measure */,
    why: 'Math.random in render/layout/input code breaks byte-exact screenshot determinism',
    re: /\bMath\.random\b/ },
  { id: 'instanceof-type-test', baseline: 105 /* re-measure */, // Pharo: ReBadMessageRule (isKindOf:)
    why: 'the type-test-elimination campaign (memory: type-test-elimination-campaign) drove instanceof down; this locks the tail against regrowth — prefer polymorphism',
    re: /\binstanceof\b/ },
];
```

Notes for the executor:
- `constructor.name` (21 sites) was considered and NOT seeded: the census itself documents
  `new @constructor` / `@constructor.name` as a legitimate universal idiom here; adding it would
  ratchet an idiom, not a smell. Record this as a considered-and-rejected note in the doc update.
- The stink engine scans `Fizzygum/src/` only (not the harness). That is correct for these seven.
- If a count is wildly off the estimate (e.g. `undefined` ballooning because the naive strip counts
  string occurrences like `typeof x is 'undefined'`), either accept the higher baseline (it is
  relative — ratchets measure regressions, not absolutes) or upgrade the engine's `stripComment` to
  the `stripLine` string-masking version from check-layering.js. Prefer accepting the measured
  baseline in this arc; note the masking upgrade as a follow-on.
- Self-test: temporarily add a `debugger` line to any `src` file → gate must FAIL naming it; remove
  it → OK. (Baseline stinks fail on EXCEEDING baseline, so +1 over a just-measured baseline fails.)

Acceptance: `node ./buildSystem/check-stinks.js` prints all seven `OK` at their baselines;
`fg build` passes; a planted extra `debugger` fails the build; fixture removed.

---

## Phase 3 — `census-hierarchy-duplication.js` (ADVISORY): identical-to-super & just-sends-super

**Pharo ancestry:** `ReEquivalentSuperclassMethodsRule` (an override whose body is equivalent to
what it would inherit adds nothing), `ReJustSendsSuperRule` (an override that only forwards to
super), `ReLocalMethodsSameThanTraitRule` (a method identical to what the mixin already provides).
This is the hierarchy-aware complement to the existing duplication tooling
(`./find_duplicated_code.sh` jscpd exact-clone scan; `./find_similar_code.sh` jsinspect structural
scan) — those find textual/structural clones but do not reason about inheritance, so they can't say
"this override is REMOVABLE".

**Advisory, not a gate**: always exits 0 (2 on operational error), like
`census-public-private-calls.js`. Support `--json <file>` for Phase 5.

### 3.1 Mechanics

1. Build the class model: name → `{parent, mixins[], methods: {name → bodyLines}}` for every class
   in `Fizzygum/src/`. Reuse/require the parse phase of `census-public-private-calls.js`
   (`classInfo` + `chainOf`/`resolve`, which already handle `extends` + `@augmentWith` mixins and
   the mixin `onceAddedClassProperties` DSL); if requiring proves awkward, copy the parse phase —
   copied scanners are the codebase's current idiom (documented in lint-and-static-checks.md §3).
2. For every method `M` defined in class `C` that is ALSO defined somewhere up C's chain
   (mixins + parent chain — use the census's resolution order), find the NEAREST inherited
   definition and compare **normalized bodies**: strip comments (stripLine-grade), drop blank
   lines, collapse internal whitespace runs to one space, keep everything else verbatim.
   Identical ⇒ report `IDENTICAL-TO-INHERITED` (candidate: delete the override).
3. Independently, flag `JUST-SENDS-SUPER`: an override whose entire normalized body is the single
   token `super` (the **bare, argument-forwarding** form).
   ⚠ **`super()` and `super arg…` forms are NOT flagged** — in CoffeeScript, bare `super` forwards
   the caller's arguments, so a bare-`super`-only override is dispatch-equivalent to no override;
   but `super()` explicitly passes ZERO args, which differs from absence whenever the parent reads
   arguments. Only the bare form is a removal candidate.

### 3.2 Caveats to embed in the report header (case-law, do not skip)

- **super is meta-compiled here.** `src/meta/Class.coffee` (`_equivalentforSuper`, ~:63-85) rewrites
  every `super` form when compiling fragments in-browser; a trailing space after bare `super`
  silently drops forwarded args (a real past bug — the reason `check-trailing-whitespace.js`
  exists). Textual equivalence is therefore a CANDIDATE signal, never a proof — every finding
  requires human/LLM verification before any (out-of-this-arc) removal.
- **Deliberate seams exist and must not be "cleaned up":** the duplication-refactor arc
  (2026-07, triage ledger at `Fizzygum/duplication-report/triage-report.md`, gitignored; conventions
  in `docs/duplicated-code-detection.md`) established that the `_apply*/_commit*` corner twins, the
  `*Base` override-bypass twins, and the mapRect twins are deliberate same-class seams. They are
  same-class siblings (not overrides) so they should not appear here — if any does, classify it
  under the ledger's existing "deliberate seam" category rather than as removable.
- An override identical to a MIXIN-provided method: report separately as `SHADOWS-MIXIN` (the
  resolution order between an own def and an `@augmentWith` copy is a meta/Class.coffee detail —
  flag it, let the human decide which copy wins and which should go).

### 3.3 Deliverable & acceptance

- Script in `buildSystem/`, run from `Fizzygum/`:
  `node ./buildSystem/census-hierarchy-duplication.js [--json out.json]`.
- Human-readable report: one line per finding —
  `IDENTICAL-TO-INHERITED  Foo.coffee:@bar == Widget.bar (12 lines)` — sorted by body size
  descending, with a summary count per category.
- Findings are APPENDED (as a new dated section) to the duplication triage ledger
  `duplication-report/triage-report.md` following that file's existing entry format (read it
  first; it is gitignored working state — if absent, create `duplication-report/` and start the
  section, noting the convention source `docs/duplicated-code-detection.md`).
- **No src edits in this arc.** The report IS the deliverable; acting on findings is a future
  triage arc.
- Acceptance: runs clean in ≲ 5 s; spot-verify 3 findings by opening both method bodies; `--json`
  output parses.

---

## Phase 4 — `census-property-placement.js` (ADVISORY): pull-up & demote candidates

**Pharo ancestry:** `ReInstVarInSubclassesRule` (the same instance variable declared in every
subclass → pull it up) and `ReVariableReferencedOnceRule` (an ivar used in only one method, assigned
before read → should be a local/temp). Advisory, always exits 0, `--json` supported.

### 4.1 Property harvest

For every class: (a) class-body property defaults — 2-space `name: <value>` entries whose value is
NOT a function arrow (the same HEADER position, different right-hand side), e.g.
`bounds: nil`, `color: Color.create 80,80,80`; (b) constructor/instance assignments `@name = …`
anywhere in the class body. Union = the class's "declared properties".

### 4.2 Report 1 — PULL-UP candidates

For every parent class `P` with ≥ 2 subclasses in `src/`: a property declared in **every** direct
subclass of `P` but not in `P` itself (nor anywhere up P's chain) → report
`PULL-UP  <prop>: declared in <k>/<k> subclasses of <P> (defaults: same|differing)`. Same-default
findings are the strong candidates; differing-default ones are informational.

### 4.3 Report 2 — DEMOTE candidates (property → local)

A property whose every `@prop` occurrence (reads AND writes) sits inside exactly ONE method of the
class (and none of its subclasses/superclasses touch it), AND whose first textual occurrence in
that method is an assignment → report `DEMOTE  <Class>.<prop>: only used in @<method>`.

**Safety exclusions (must-implement, each has bitten before):**
- Skip any property whose NAME appears as a quoted string anywhere in src or harness
  (serialization protocol lists, `serializationTransients`, dynamic `@[property]` walks in
  `DeepCopierMixin` are property-name-driven — the same strings-count-as-references lesson
  check-dead-methods already encodes).
- Skip properties on classes reachable from `Widget` — WARN-tier only, don't drop them, but tag
  them `[inspector-visible]`: the inspector renders live member lists, and a Widget-family FIELD
  change churns exactly 15 SystemTest screenshots (the `fg recapture-inspector` set — probed
  empirically 2026-07-12). Any FUTURE arc acting on a tagged finding must budget an inspector
  recapture.

### 4.4 Deliverable & acceptance

Same shape as Phase 3: report + dated ledger section + `--json`; no src edits; runs ≲ 5 s;
spot-verify 3 findings per report.

---

## Phase 5 — aggregation (`fg critique`) + documentation

### 5.1 `fg critique` (LOCAL edit to `/Users/davidedellacasa/code/Fizzygum-all/fg` — uncommitted)

Add a `critique` subcommand — the Critic Browser analogue: ONE read-only command that surfaces the
whole advisory tier plus every "you could tighten a ratchet now" signal. It runs, in order, each
step timed, total budget ~30 s, always exit 0:

1. `node buildSystem/check-stinks.js` → reprint any `UNDER`/tighten notes.
2. `node buildSystem/check-dead-methods.js` → reprint stale-allowlist NOTEs.
3. `node buildSystem/check-unresolved-sends.js` → reprint stale-allowlist NOTEs.
4. `node buildSystem/census-public-private-calls.js` → the R2/R3/R4 summary counts.
5. `node buildSystem/census-hierarchy-duplication.js` → summary counts per category.
6. `node buildSystem/census-property-placement.js` → summary counts per report.
7. Footer: "advisory only — nothing here gates; see docs/lint-generic-rules-carryover-plan.md".

(Do NOT run jscpd/jsinspect here — minutes-slow; they stay on-demand via `find_duplicated_code.sh`
/ `find_similar_code.sh`.) Update fg's `usage()` text. Remember: fg is not in any repo — this edit
produces no git diff and needs no commit.

### 5.2 Documentation updates (committed, in `Fizzygum/`)

- `docs/lint-and-static-checks.md`:
  - §3 gate table: add the `unresolved-sends` row (file, wiring anchor, enforces, ratchet =
    `unresolved-sends-allowlist.txt`).
  - §3 per-gate notes: a paragraph mirroring the dead-method note (harvest scope, over-approximated
    def set, vendor allowlist, self-skip without tests repo, the dead-methods symmetry).
  - §5: add the new allowlist file to the central-allowlist list.
  - New short §: name the two advisory censuses (hierarchy-duplication, property-placement) beside
    the existing public-private census, and `fg critique` as the aggregator (with the note that fg
    is local tooling).
  - **Severity-policy paragraph** (make the implicit explicit, one paragraph): *sound negative ⇒
    hard gate; count-shaped smell ⇒ ratcheted stink/baseline; suspected/heuristic ⇒ advisory
    exit-0 census — an unsound signal must never gate (a false gate-pass bakes regressions into
    byte-exact references; see fg classify's documented safety asymmetry).*
  - Considered-and-rejected notes: `constructor.name` stink (legit idiom), console.log stink
    (owner-parked, see §8.6), transitive anything (already rejected, §7 there).
- Update the stinks section of that doc: it currently says the STINKS table is empty — list the
  seven seeds and their whys.

---

## Phase 6 — end-of-arc verification & review

1. `node` each new/edited checker directly once more (clean + self-test).
2. `/Users/davidedellacasa/code/Fizzygum-all/fg build` → PASS with the new gate summary lines
   visible.
3. Full close: `/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet > /tmp/fg-gauntlet-run.log 2>&1`
   with `run_in_background: true`; wait for the completion notification; check
   `cat /tmp/fg-gauntlet.verdict`. Since this arc touches zero behaviour source, every leg must
   pass with **zero screenshot diffs and zero recaptures**; any red leg other than the documented
   boot-storm infra flake (`[shard N] did not start within 90s` / `CoffeeScript is not defined`,
   auto-retried by the gauntlet) means a tooling mistake — investigate, do not recapture anything.
4. ONE end-of-arc review pass over the whole diff (`git -C /Users/davidedellacasa/code/Fizzygum-all/Fizzygum diff` +
   `status`): expected footprint = new `buildSystem/check-unresolved-sends.js`,
   `buildSystem/unresolved-sends-allowlist.txt`, `buildSystem/census-hierarchy-duplication.js`,
   `buildSystem/census-property-placement.js`; edited `buildSystem/check-stinks.js`,
   `build_it_please.sh`, `docs/lint-and-static-checks.md`, this plan's STATUS line; NOTHING under
   `src/`. (Plus uncommitted local `fg` edits and the gitignored ledger append.)
5. Present to owner: summary, the two advisory reports' headline counts, proposed commit message
   (via `git commit -F`, message ends with the standard Co-Authored-By/session trailer). **WAIT for
   approval. Do not commit or push without it.**

---

## §8 Backlog — surveyed 2026-07-15, DEFERRED, owner-gated (record only; do not execute)

These were reviewed in the same Pharo-carryover analysis and deliberately left out of this arc.
Each carries enough context to spawn a future arc cold.

1. **A2 — action-string resolution.** Menu/button actions are dispatched by STRING method name;
   recorded case law: "button-action strings never get `_`-renamed" (public-private call-separation
   arc). A checker harvesting string literals in action positions (survey the call shapes first:
   grep `src/basic-widgets/menu-system/` for how `MenuItemWdgt`/trigger actions are passed) and
   requiring membership in the census `allMethodNames` closes the string-dispatch hole that
   Phase 1's `[@.]name(` scan cannot see.
2. **A3 — must-call-super table.** Table-driven rule: an override of a listed method must contain
   `super`. Seed from the recorded WindowWdgt SUBCLASS-SUPER trap (FolderWindowWdgt; memory
   `accidental-complexity-reduction-plan`). Census has hierarchy + bodies; ~a dozen lines + table.
3. **A4 — paired-method contracts.** Table-driven "defines X ⇒ must define Y" (Pharo:
   `ReDefinesEqualNotHashRule`). Known pair: the bounds-cache SLOW twins — a cache override must
   override BOTH world+hand variants (memory `fizzygum-bounds-cache-assessment`; currently only the
   runtime cache-oracle gate would catch it). Survey `docs/serialization-duplication-reference.md`
   for ser/deser hook pairs before writing the table.
4. **A6 — dead classes.** `ReClassNotReferencedRule`: a class referenced by no `extends`/`new`/
   `@augmentWith`/name-token outside its own file. Reference universe MUST include the harness
   (`Fizzygum-tests/Automator-and-test-harness-src/` — SystemInfo was live only via a harness
   `extends`; memory `dead-code-gate-must-include-harness-src`). `src/boot/dependencies-finding.coffee`
   already regex-harvests the reference edges.
5. **C — metrics ratchet.** Per-file line/method-count baselines for the top-N god files
   (`Widget.coffee` = 4,950 lines) to support `docs/god-class-decomposition-plan.md` ("must not
   grow while the plan is pending"). Advisory `fg metrics` first; promote to ratchet when the
   decomposition arc starts.
6. **console.log policy — ✅ RESOLVED 2026-07-15 (owner decision: ACCEPT AS-IS + fix the error verbs).**
   The finding below is literally true but **operationally empty**, and the follow-up measurement is the
   part worth keeping: of **224** non-comment `console.log` sites, **201 sit behind an explicit debug
   flag** (`if @detailedDebug` — 154 in `LCLCodePreprocessor.coffee` alone; `if
   window.srcLoadCompileDebugWrites` in `meta/Class.coffee`), and **every one of the remaining 23** was
   read and is inside a multi-line debug guard, an audit block (`UNDECLARED-EOC`/`PAINT-SCHEDULES`), an
   Automator-only path (`TreeNode`), or a genuine error handler. **Nothing logs during normal
   operation.** So:
   - **(a) `drop_console` was REJECTED as actively harmful** — it would strip the error diagnostics we
     WANT in production (`Class.coffee:418` "error evaling", `VideoPlayerWithRecommendationsWdgt` "error
     loading manifest"). The size argument does not hold either: class sources ship as escaped TEXT and
     compile in-browser, so terser never sees them — it only touches boot, the loaders, and the homepage
     pre-compiled image; the `console.log` text ships regardless.
   - **(b) a ratcheted `console-log` stink was REJECTED** — it would ratchet a disciplined, flag-guarded
     debug idiom, not a smell. Exactly the `constructor.name` mistake already rejected above.
   - **(c) ACCEPTED as-is.** The one real finding inside the item: **6 genuine error paths used
     `console.log` where `console.error` is the right verb** — converted 2026-07-15
     (`meta/Class.coffee:103,418`, `meta/Mixin.coffee:64,116`,
     `VideoPlayerWithRecommendationsWdgt:36,37`). That is not cosmetic: `console.error` is the
     ESTABLISHED failure signal the gates key off ("CI / the smoke-apps app-launch gate key off
     console.error" — `WorldWdgt.coffee:1554`), alongside `RECALC_NONCONVERGENCE` / `LAYOUT_ERROR` /
     `DATAFLOW_ERROR`. So those six failures are now visible to the boot-smoke and apps gates instead of
     scrolling past as logs. Verified: build + boot smoke green on native AND SWCanvas (none of the six
     fires in a healthy build), full gauntlet green.

   *(Original finding, kept for the record:)* contrary to prior belief, console.logs are
   **NOT stripped from the production build**: `drop_console` appears nowhere in
   `build_it_please.sh`, and `terser --compress` (used at ~:587 boot, ~:650-657 loaders, ~:782
   pre-compiled homepage image) keeps `console.*` by default; no runtime override reroutes
   console.log in `src/boot/`. 213 non-comment `console.log` sites ship in every build including
   `--homepage`. Options when the owner wants this: (a) add `--compress` option
   `drop_console=true` (or `pure_funcs=['console.log']`, keeping warn/error) to the HOMEPAGE terser
   invocations only — smallest change, prod-only; (b) a ratcheted `console-log` stink (baseline
   ~213); (c) accept as-is. OWNER DECISION NEEDED before any of these.
7. **Phase-1 v2 reach.** Paren-less call harvesting (`@foo arg`); macro-`.js` call scanning;
   hierarchy-RESOLVED `@`-self sends (an `@`-call must resolve within the receiver class's own
   chain, not just globally — census `chainOf` enables it; needs a duck-typing escape). Also the
   free by-product: `fg who-implements <name>` / `fg who-sends <name>` CLI queries over the same
   harvest (Smalltalk browser queries as commands).
8. **Stink-engine masking upgrade.** Swap check-stinks' naive `#`-strip for the shared
   `stripLine` string-masking (needed the day a stink regex collides with string contents).
9. **Empty-catch stink.** `ReEmptyExceptionHandlerRule` (~23 catch sites total today) — needs a
   two-line matcher, i.e. the multiline extension of the stink engine.

## §9 Rollback

Any new gate misbehaving: `./build_it_please.sh --noSyntaxCheck` confirms the failure is the gate
(it skips ALL gates), then run the single checker directly for its stderr. Surgical rollback =
delete the gate's wiring block in `build_it_please.sh` (build reverts to prior behaviour; the
checker file can stay, unwired). Stink rollback = remove the entry from `STINKS`. Advisory scripts
cannot break the build (never wired). `fg` edits: local file, revert by hand.

## Appendix — measurements & probe learnings (2026-07-15, for re-verification)

- Scale: 486 `.coffee` files, ~54k lines, ~455 classes under `Fizzygum/src/`.
- Grep-estimated counts (non-comment lines; the stink engine's own count is authoritative):
  `debugger` 36 · `console.log` 213 · `console.warn|error` 9 · `undefined` 89 · `null` 10 ·
  `Date.now|new Date(` 19 · `setTimeout|setInterval` 5 · `Math.random` 5 · `instanceof` 105 ·
  `constructor.name` 21 · catch-sites ~23.
- Probe: `Fizzygum-tests/.scratch/probe-sends-not-implemented.js` (gitignored, disposable). Def
  harvest of 4,064 names left 21 unresolved call names, all explained (§1.1). Its in-file BUILTINS
  set is the Phase-1 seed.
- Pharo source material: SmallLint/Renraku rule catalogue as shipped in current Pharo
  (github.com/pharo-project/pharo, packages `General-Rules`/`Renraku`); *Pharo with Style*
  (S. Ducasse); Renraku paper (Tymchuk et al., IWST 2017). The mechanism map and the
  carried/rejected rule triage live in the 2026-07-15 session that authored this plan.

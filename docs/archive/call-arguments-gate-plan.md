# The call-arguments gate: extra arguments, positionals into options, and what they found

STATUS (2026-11-07): COMPLETE — archived. Owner round answered ("go with your recommendations", §2); Units A–E
done, the close gauntlet 20/20, one independent review (R1–R14 addressed); ledger in §5. Item 1 of `docs/BACKLOG.md`'s `archive/argument-holes-both-repos-plan.md` section; items 2 and 3 of
that section follow in their own rounds.

## §0 Orientation (cold start)

- `Fizzygum/buildSystem/lib/call-sites.js` is the ONE table of every call site in both repos (Fizzygum's src, the
  tests repo's harness, macro sources, the MacroToolkit heredocs, the tests repo's scripts), read by real parsers
  (the browser's CoffeeScript 2.0.3 through the meta-compiler; acorn for JS). `check-argument-holes.js` judged it
  for one rule, HOLE (R3 of `docs/architecture/constructor-and-parameter-conventions.md`). Its archived plan:
  `docs/archive/argument-holes-both-repos-plan.md` (rulings D1–D5, review R1–R7).
- The conventions doc §5 stated the limit this arc closes: a POSITIONAL argument handed to an `(opts = {})` head
  is taken AS the options object, silently — the trap of every conversion to options. And dead arguments (an
  argument no parameter receives) were unseen.
- The survey (read-only) lives in `Fizzygum-tests/.scratch/over-arity/` (`SURVEY.md` + probes + `out/`).

## §1 Survey findings (2026-11-07)

1. Matching a call to its callee BY NAME is unsound for this rule: 1,860 "over-arity" calls, ~1,830 of them
   foreign APIs sharing a name with ours (`Math.max` vs `Point::max`, `ctx.moveTo` vs `Widget::moveTo`,
   `Object.keys`, `path.resolve`, `n.toString(16)`). Foreign definitions are invisible, so by-name invents defects.
2. Judging only calls whose receiver is provably ours (`new`, `super`, `@m`, `ClassName.m`, bare calls), against the
   definitions that call FORM can reach (a bare call → name bindings; a send → class/mixin members and property
   assignments; object-literal keys → nothing), max over them: 18,521 calls judged, 13 extra-argument sites, all
   real, none false. Resolving `@m` through the class graph instead (chain + descendants + mixins + harness
   installs) judged 3% more and found the same 3 method sites — not worth the machinery.
3. The 13: a REAL BOOT BUG — `src/boot/globalFunctions.coffee`'s `bootLoadPromises = [ f "a",⏎ # …⏎ f "b" ]`
   compiles to ONE element `f("a", f("b"))` (since 0ad2048b, 2020-10-26), so `Promise.all` never awaits the
   CoffeeScript library. Proven: a prelude holding that `<script>` 3 s fails every page with `ReferenceError:
   CoffeeScript is not defined` (control 9.1 s OK; the same hold on the AWAITED `pre-compiled.js`: 18.2 s OK). A
   40-page boot storm on the current build: 4/120 fail, all with exactly that error — the signature the runners
   call the "boot-storm infra flake (a dropped `<script>`)". 16-page storms: 0/48. Then 9 constructor supers passing
   a size Point no constructor reads (Widget ×6: BinWdgt, SimpleLinkWdgt, StretchableWidgetContainerWdgt,
   FridgeMagnetsWdgt, VideoPlayerWdgt, VideoPlayerWithRecommendationsWdgt; CodeAreaWdgt ×3: CodePromptWdgt,
   ScriptWdgt, ConsoleWdgt); `@_chromeHeight spec` (its `spec` dropped by 3477df2d; +2 `frame._chromeHeight` twins
   on an unknown receiver); `@createBufferCacheKey h, v` (the key reads both itself);
   `@simplifyFunctionDoingSimpleInvocation code, error, userDefinedFunctions` (takes two).
4. An `= {}` parameter receiving an argument of known non-object kind (`@`, a literal, `new`, an array, a
   function): 0 of 427 sites today (397 object literals, 30 opts-shaped expressions). Over-arity alone misses the
   single positional `new SimpleButtonWdgt @`.
5. A swallowed-sibling spelling scan over 38,132 CoffeeScript calls: one real instance (the boot bug), which the
   extra-argument rule catches; no separate rule.
6. The lib's lexical-locals rule missed destructured and loop bindings (`for (const [a, b, fn] of …)`): a bare call
   of one keyed as a global name. HOLE is unchanged by the fix (0).

## §2 Rulings (owner: "go with your recommendations", after a clean-minimal / Right-Thing re-check)

- **D1 EXTRA_ARGUMENT:** a call passes more arguments than any definition it can reach declares (written count; a
  trailing `undefined` counts). Judged only where the receiver is provably ours; reach by call form; max over the
  reachable definitions; a splat/rest/expansion parameter or a body reading `arguments` (a forwarding bare `super`
  included) = unbounded; any reachable DATA definition (a field holding a closure, a parameter, a reassigned or
  destructured name) = not judged. One callee key per site as before (D2(a), by name); the site gains whether its
  receiver is ours, each definition its declared count, `= {}` slot and form. Exact zero, no baseline, no marker.
- **D2 POSITIONAL_INTO_OPTIONS:** an `= {}` parameter receiving an argument of known non-object kind. Stated limit:
  a lone variable (`new X target`) — closing it would invent a naming law.
- **D3:** one gate, renamed `check-argument-holes.js` → `check-call-arguments.js` (rules HOLE, EXTRA_ARGUMENT,
  POSITIONAL_INTO_OPTIONS — all judge a call's arguments against its callee); its proof renamed with it, planting
  each rule. `census-call-arity.js` keeps its name.
- **D4 residue:** the boot array → explicit parentheses, comment corrected; then the 40-page storm re-run: 0/120 ⇒
  the "boot-storm" diagnosis was this bug, and every workaround whose ONLY stated reason is that flake retires (the
  750 ms stagger, the fresh-page reload retries, the serial-only constraints, the "don't boot your own page"
  reasons), with the two CLAUDE.md notes rewritten; failures remain ⇒ keep them, reword to the measured cause.
  BinWdgt: honour its comment (a naked bin IS built: `WidgetFactory.underTheCarpet`) — `super()` then
  `@__commitExtent new Point 340, 270`, the InspectorWdgt idiom; the other 8 size Points deleted; the 3 dead method
  arguments deleted (both `frame._chromeHeight` twins too). `w.tripleActivated pos` and `spec.after t, results`
  stay (protocol hooks; unknown receivers, unjudged). `fg homepage` joins the gates (boot is touched).

## §3 Units

- **A — the table:** `lib/call-sites.js` gains the definitions table (`defs`), each site's receiver-is-ours, each
  argument's static kind, the destructuring/loop-variable locals, and `arityTest`; one `call-sites-selftest.js` case
  per new reading.
- **B — the gate:** `git mv` to `check-call-arguments.js` (+ `-selftest.js`), the two rules, their plants;
  `build_it_please.sh`, `fg lint-report`'s step, every live reference.
- **C — the residue** (Fizzygum src, Edit tool): the boot fix, BinWdgt, the 11 dead arguments.
- **D — the storm, before/after,** and what it decides in the tests repo's rigs.
- **E — docs:** the conventions doc (§5, the spelling trap), the lint index, both CLAUDE.md files, BACKLOG, this
  plan's archive + INDEX line at close, memory. Close: `fg gauntlet` + `fg homepage`, one independent review.

## §4 Protocol

`fg build` after every unit (the gate's proof runs on every build); a rule is believed only after its plant has
failed it; `fg gauntlet` + `fg homepage` at the close, in the background; commits only on the owner's approval of
each (`git commit -F <file>`), push asked separately.

## §5 Ledger

- 2026-11-07 — Survey + owner round (§1, §2).
- 2026-11-07 — **Unit A** (`lib/call-sites.js`): the definitions table `defs` (CoffeeScript: class-fragment members,
  one binding walk for every unit — parameters, `@field` parameters, destructurings, loop variables, assignments by
  form; JS: declarations, destructurings with `require(…)` as an import, member/field/key forms), `csSignature` /
  `jsSignature` (count, `arguments`/splat/rest = Infinity, the `= {}` slot), each send's `via` (the depth of `->`
  rebinding per unit: class member 1, macro 1, mixin 2, boot 0; JS `this` in a class method, `super.m`), each
  argument's `kind` (parentheses and an interpolated string unwrapped — a first cut read `(Object.assign {}, opts…)`
  as a literal: 2.0.3's Parens and StringWithInterpolations share the `body` shape), and `arityTest`. The real trees:
  50,837 calls, 0 holes (unchanged), 18,992 judged for arity, the 13 of §1.3, 0 into options. `call-sites-selftest`
  36 → 57 cases; six mutations (bare calls reaching every form, every send judged, `arguments` ignored, no parens
  unwrap, imports defining, no loop variables) each seen failing its case; restored byte-identical.
- 2026-11-07 — **Unit B**: `git mv` → `check-call-arguments.js` + `-selftest.js` (rules HOLE, EXTRA_ARGUMENT,
  POSITIONAL_INTO_OPTIONS; the control holds `Math.bpTrail 1, 2, 3` — by name alone an extra argument — and an
  object in an options slot; plants: both arity rules in src (incl. the swallowed-element spelling) and in the tests
  repo (harness, script, macro)); 35 cases; mutations "every send judged" and "options slot never read" each fail
  the proof. `build_it_please.sh`, `fg critique`'s step, census-call-arity / census-widget-conformance /
  tests-repo-code references.
- 2026-11-07 — **Unit C** (src, Edit tool): boot's `bootLoadPromises` elements parenthesized (compiled by 2.7 and
  2.0.3: two elements); BinWdgt `super()` + `@__commitExtent new Point 340, 270`; 8 dead size Points → `super()`;
  `_chromeHeight` ×3, `createBufferCacheKey`, `simplifyFunctionDoingSimpleInvocation`'s third argument deleted.
  Gate: `0 holes, 0 extra arguments, 0 positionals into options over 50829 calls`. `fg build` OK.
- 2026-11-07 — **Unit D, the storm** (`Fizzygum-tests/.scratch/over-arity/storm.js`, 40 harness pages booted at once,
  no stagger): before the fix 116/120 (4 × `CoffeeScript is not defined`, rounds ~126 s — a failed page waits out the
  120 s bound); after 120/120 (rounds ~15 s), then 10 more rounds 399/400 — the one failure a browser LAUNCH timing out
  at puppeteer's 30 s bound (no page loaded), 0 × `CoffeeScript is not defined` in 520. 16-page storms: 48/48 before.
  ⇒ the "boot-storm infra flake" was this bug. RETIRED (their only stated reason): the boot-failure reload retries of
  run-all-headless.js, run-paint-audit.js, serialization-roundtrip-headless.js, serialization-file-roundtrip-headless.js,
  smoke-apps-headless.js (its selftest's WORLD_NOT_READY lines updated) — a world that never boots is now a finding;
  run-audit-loop.sh's 6-shard default (→ the runner's 8). KEPT, reason corrected: the LAUNCH staggers (run-all-headless,
  run-paint-audit, recapture.js's LAUNCH_STAGGER_MS) — the measured launch timeout under a burst is their reason; the
  serialization rig's page reuse (a compile-at-boot page costs the wave seconds); make-diff-page's serial dumping (one
  browser at a time; no storm reason left); recapture's single-process re-verify (load flakes); lib/shards.js's probe
  retry (a launch or navigation that throws under load). Notes rewritten: root CLAUDE.md, Fizzygum-tests/CLAUDE.md, fg.
- 2026-11-07 — **Close gate:** `fg gauntlet` 20/20 OK (970 s, no load-flake retry) on the retired retries; pixels
  unchanged (BinWdgt's naked extent included). `fg homepage` OK.
- 2026-11-07 — **What the boot fix costs PRODUCTION** (a `--profile homepage` tree, which needs no compiler to boot;
  `.scratch/over-arity/prod-boot-order.js`, 15 runs each, alternating, cache off): world-ready median 59.6 ms as
  built (both awaited) vs 56.1 ms with a plant resolving the CoffeeScript load at once (the bug's boot) — ~3.5 ms,
  ranges overlapping (45–62 vs 42–67): the library executes on the main thread (~30–35 ms) awaited or not, in a random
  order with the image (after it in 10/15 runs). Kept as is — one await path, the batch's stated intent — rather than
  a second, conditional await where compiling begins.
- 2026-11-07 — **Close: ONE independent review** (a fresh agent given the rulings and both diffs; read-only probes
  under `Fizzygum-tests/.scratch/review-call-arguments/`). Nothing fired on today's trees; HOLE verified unchanged
  against HEAD's lib (50,810 sites, 0 holes, the same 23 values). Its findings, all addressed:
  - **R1–R9 (the dangerous direction: an EXTRA_ARGUMENT on correct code):** the reach could miss a call's true
    target — a class whose chain ends in a FOREIGN base (`extends Array`/`EventEmitter`: its `this`/`super` sends);
    a COMPUTED parent (`extends events.EventEmitter`) read as no parent (a 0-argument default constructor); the
    class table's first definition wins across programs and runtimes (two macros' `Probe`; a script's `class Image`
    against the page's `new Image`); a name destructured from a FOREIGN or renamed `require` reaching same-named
    bindings anywhere; a script's function reaching page code's bare calls (`open`); per-SCOPE locals (a binding
    nested anywhere made every same-named call in the file or member local — real instances:
    serialization-roundtrip's top-level `evaluate(run)` keyed to a nested `const evaluate`); a boot file's top-level
    `@` (it is `window`) read as ours; a mixin's every object key a member and every `->` a receiver; a JS getter read
    as the method. Restructured on ONE principle — a call is judged only if its target is certainly among what it
    reaches: every definition and class carries its HOME (page / verbs / a macro program / a script module) and a
    call sees what runs where it runs; bindings resolve LEXICALLY (CoffeeScript frames with capture of an outer —
    or top-level — assignment; JS function scopes); `@` is ours only in a RECEIVER function (a class member, a macro
    or verb, a mixin member); a send needs a fully read class chain and some member or field of its name, and then
    also reaches function-valued object keys (a computed install, `X::[k] = v` — the reviewer's P16); `new
    @constructor` is not judged; imports: relative + unrenamed only. Of the reviewer's 27 fixtures, the 23 correct
    programs now draw no verdict and the 3 real extra arguments (an arrow in a method, a top-level call past a
    nested loop variable — a former MISS — and a JS class field) are caught.
  - **R10 (a miss):** JS class fields were in `defs` but not in `ours` → now ours.
  - **R11–R14 (docs):** "provably ours" overstated → the headers, §5, the lint index, both CLAUDE.md files and the
    build comment say "its target is certainly among what it reaches"; the root CLAUDE.md's "never retried away"
    corrected (fg's leg retry and the audit gates' shard retry are whole-run mechanisms) and "0/520" made exact (no
    CoffeeScript failure in 520; one launch timeout); `plans/pixel-icons-plan.md`'s storm reason for serial
    capture removed; BACKLOG's closure names the lone-variable limit.
  - `call-sites-selftest` 57 → 71 cases (one per finding, in a fixture whose every file is asserted READ — the first
    cut's fixture lacked a `tests/` dir, so its script cases passed on nothing: caught by two positive cases failing);
    nine mutations (foreign base ignored, homes ignored, CS capture ignored, every `@` ours, getter callable, every
    home seen, keys alone suffice, `new @constructor` judged, imports never resolved) each fail their case.
    Real trees: 0 / 0 / 0 over 50,810 calls, 19,268 judged for arity (18,976 before the restructure).

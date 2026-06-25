# Plan — ratchet up the layout-flow lint rules & static checks

**STATUS: EXECUTED 2026-06-25 (Fizzygum master, pending commit).** Don't re-run the rejected closure. Outcome:
- **Phase 1 — rule [G] LANDED in DIRECT form.** A low-level method must not call a structural self-settling wrapper
  (the `_settleLayoutsAfter` callers, discovered structurally; 12 wrappers, 0 hits = forward-prevention) — plus the
  unambiguous `@add` self-form (`@add` == Widget.add inside a Widget method). `# nosettle-sanctioned` escape marker.
- **The TRANSITIVE closure (Phase 1b) was prototyped and REJECTED as INTRACTABLE — do NOT re-attempt.** A name-based
  backward-reachability fixpoint balloons to ~720–870 names / ~500–710 false hits (`constructor`→`buildAndConnectChildren`
  →`add` is a universal hub; the raw setters / `*NoSettle` cores land in the set, so it flags the very "cores call cores"
  pattern it should bless). Name-based reachability can't model the orphan guard. Excluded too: the `.add` MEMBER form
  (`Point#add` name collision — the `@add` self-form IS covered) and `collapse`/`unCollapse` (the SwitchButton-collapse
  OPEN item, graduated to the end-of-cycle-flush drawdown campaign, not bundled here).
- **Phase 2 (rule [E] completeness):** census → no innocent-named escapee; the immediate-mutator name set == the
  geometry writers. No rename.
- **Phase 3 (rule [D] tightening):** assessed NOT-YET-RIPE — the 6 remaining macro raw-uses are measure-and-size
  read-backs on orphans with no behaviour-preserving public alternative. Not tightened.
- **Phases 4 & 5:** stay parked/gated (Phase 5's precondition — the drawdown OPEN set resolved — does not hold).
- **§4:** docs point at the `isLowLevel`/`isImmediateMutator` predicates; gate comments de-staled.
- **Follow-ups surfaced — both now DONE (2026-06-25):** (a) **`/Layout$/` arm removed** (`e13c44c6`): the vestigial arm
  matched only non-pass methods (`implementsDeferredLayout`, the `*HorizLayout` menu actions,
  `countOfChildrenInHorizontalStackLayout`); removed it, PAIRED with an `APPLY_CALL` lookahead skipping reference
  comparisons (`@_reLayout != Widget::_reLayout`, the implementsDeferredLayout idiom) so the reclassified base isn't a
  false `[F]` hit, and retired the `# nosettle-sanctioned` marker on `newParentChoiceWithHorizLayout`. (b) **collapse/
  unCollapse convert DONE** (`86d3b1e8`, drawdown campaign): the layout-pass call-sites routed to the idempotent
  `_collapseNoSettle`/`_unCollapseNoSettle` cores + `SwitchButtonWdgt.mouseClickLeft` converted to self-settle (the
  32-record residual eliminated, total 73 → 38); `[G]` now covers collapse/unCollapse (removed from `WRAPPER_EXCLUDED`).

**For the CURRENT STATE of the whole build-time checking system** (the gate inventory, rules [A]–[G], the markers, the
predicates, the reasoned boundaries, how-to extend/debug) see the canonical reference **`docs/lint-and-static-checks.md`**.
This plan is now only the execution + rejected-transitive *record*.

Original plan below (the executable-cold spec) — kept for provenance; the rejected-closure sections (Phase 1b) are
superseded by the STATUS above.

**Originally: PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.** Everything needed
(background, the architecture it protects, the existing lint harness, the exact predicates + file:line anchors, the
proposed rules, verification, workflow) is embedded inline — you should not need to have seen the conversation that
produced this. Lines drift; grep the named symbol, don't trust the number.

**One-line purpose:** the layout-settle architecture is held together by a runtime invariant (one flush per public
mutation; low-level code never settles). Today that invariant is enforced *partly* at build time (`check-layering.js`,
direct/name-recognized calls only) and *partly* at runtime (a `throw`, only on paths the tests exercise). This plan
**ratchets the static coverage up** so the invariant is checked exhaustively at build time — turning runtime backstops
into compile-time guarantees — plus a few smaller completeness ratchets. The motivating belief (owner): **maintaining
code + flow quality long-term depends on these checks; a convention that isn't a gate rots.**

---

## §0 — Cold-start orientation (workspace, build, test, conventions)

**What Fizzygum is.** A CoffeeScript GUI framework ("web OS": windows, desktop, drag-drop, live in-system editing)
rendered on ONE HTML5 `<canvas>`, descended from Morphic.js. ~470 `.coffee` classes in `Fizzygum/src/`. **No module
system** — every class is a global, compiled in-browser at boot; reference another class just by naming it. `nil` ==
`undefined` (a Fizzygum global). One class per file; filename == class name.

**The umbrella workspace** `Fizzygum-all/` holds three sibling git repos (the build hard-codes `../` paths):
- `Fizzygum/` — framework **source** + the build script + the lint gates (`buildSystem/`). **You edit here.**
- `Fizzygum-tests/` — the **SystemTest suite** (165 high-level "macro" tests) + the Automator harness + the Node
  scripts (`scripts/`). The tests drive the live world and compare SWCanvas SHA-256 screenshots **byte-exactly**.
- `Fizzygum-builds/` — generated build output. **Never hand-edit.**

**Commands (prefer the `fg` wrapper — path-correct from ANY cwd, fails loudly):**
- `cd /Users/davidedellacasa/code/Fizzygum-all && ./fg build` — full build; runs ALL gates (syntax + layering A–F +
  dead-method + stinks + thin-wrap + test-.js). **This is how you run the lints you're editing.** A gate failure
  aborts the build with a loud `!!!!!!!!!!! error: <gate> gate failed`.
- `./fg suite` — the 165-test SystemTest suite headless, dpr1, ~1.3 min (the fast byte-identical gate).
- `./fg gauntlet` — build + dpr1 + dpr2 + WebKit + app-smoke, all must stay 165/165 byte-identical.
- `./fg test <name>` / `./fg recapture <name>` — single test / re-baseline a test.
- Raw build (any flag): `cd Fizzygum && ./build_it_please.sh [--noSyntaxCheck]`. `--noSyntaxCheck` ALSO skips every
  lint gate (the shared escape hatch) — useful to bisect a gate bug, never to ship.

**The Bash tool here runs FISH**, and cwd resets between calls → always `cd /abs/... && …` on one line; `for x in $VAR`
does NOT word-split a string (use `bash -c '…'` for loops). macOS BSD `sed` has no `\b`. Kill orphan
`Chrome for Testing` before a suite/audit run (`pkill -9 -f "Chrome for Testing"`); never the user's Chrome.

**Workflow (review-driven project):** present each commit (diff + proposed message) and WAIT for explicit approval
unless the user directs otherwise. Commit with `git commit -F <file>` (NEVER backticks/`$()` in a `-m` — the fish/bash
shell substitutes them; `-F` reads a file, so it's safe). End every commit message with
`Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. Both repos are on `master`; push each from its
own repo dir. Benign inspector-member-list recaptures are fine — recapture, don't contort code.

**Lint changes are pure tooling** — `buildSystem/*.js` is NOT compiled into the world; editing a gate needs no rebuild
of behaviour, only a re-run of `./fg build` to see the gate verdict. A gate edit cannot change a screenshot, so the
suite/gauntlet are only needed if you ALSO rename/move source to satisfy a new rule.

---

## §1 — The architecture the lints protect (internalize this)

**The layout engine, minimally.** Widgets form a tree painted on the canvas. A geometry change marks a widget's layout
dirty (`_invalidateLayout`, which pushes onto `world.widgetsThatMaybeChangedLayout` and climbs to the parent). Once per
frame `WorldWdgt.doOneCycle` drains that queue via `recalculateLayouts()` (a converging until-loop that re-lays-out the
dirty widgets). That per-frame drain is the **end-of-cycle flush**.

**THE INVARIANT: one flush per OUTERMOST public mutation.** A *public* geometry/structure mutator
(`setExtent`/`setBounds`/`setWidth`/`setHeight`/`fullMoveTo`, the text setters, `add`/`destroy`/`close`/`fullDestroy`/
`collapse`/…) leaves the world **consistent on return** by self-settling: it runs through the **single settle tier**
`_settleLayoutsAfter` (`Widget.coffee` ~:792), which sets `world._inLayoutMutation = true`, runs the mutation's core,
then flushes `recalculateLayouts()` exactly once. Nested public calls must NOT each open their own flush.

**How the invariant is enforced at RUNTIME (the backstop you are about to make static).** `_settleLayoutsAfter`
(Widget.coffee ~:805–813):
1. **Orphan guard** — `if @isOrphan() then return coreThunk()`: a widget attached to neither world nor hand isn't in
   the live layout, so mutating it just records the change (construction inside another mutation's settle is safe).
2. **THE THROW** — `if world._inLayoutMutation or world._recalculatingLayouts: throw "a public geometry setter was
   reached during a layout flush/pass — internal layout code must use the raw/silent setters, not the public deferred
   API (see buildSystem/check-layering.js)."` Its own comment says: *"The static gate check-layering.js catches the
   name-recognized internal methods at BUILD time; **this is the runtime backstop.**"* ← THIS plan widens the static
   gate so fewer violations rely on the backstop.
3. **Batch guard** — `if world._batchingLayoutSettling then return coreThunk()`: inside `_settleLayoutsAfterBatch`
   (the deliberate multi-add coalescer) the per-mutation flush is absorbed → one flush for the bundle.
4. Else: set the flag, run the core, `recalculateLayouts()`, clear the flag.

A second runtime throw (`Widget.coffee` ~:3848): `_invalidateLayout()` throws `FLOWRULE_VIOLATION … a raw/silent/fullRaw
setter must not schedule layout (task #17)` — the runtime twin of lint rule **[E]** below.

**The settle tiers + the cores (the vocabulary the lints key off):**
- `_settleLayoutsAfter` — SINGLE settle. The canonical public wrapper. THROWS if re-entered on an attached widget mid
  flush/pass (above).
- `_settleLayoutsAfterBatch` — BATCH settle; absorbs nested settles. **Currently 0 callers**, retained as a perf
  primitive (allowlisted). The deliberate exception to "one flush per mutation".
- `_<name>NoSettle` **cores** — do the mutation + invalidate, but **never settle** ("cores call cores"). E.g.
  `_addNoSettle`, `_fullDestroyNoSettle`, `_destroyNoSettle`, `_buildAndConnectChildrenNoSettle`,
  `_setTextNoSettle`, `_reactToDropOfNoSettle`/`_reactToGrabOfNoSettle`/`_justDroppedNoSettle` (gesture hooks).
- **raw / silent / fullRaw setters** — `rawSetExtent`, `silentRawSetBounds`, `fullRawMoveTo`, … — the LOWEST tier:
  mutate geometry IMMEDIATELY, schedule nothing.

**The `NoSettle` naming convention (owner-decided 2026-06-25).** The `NoSettle` suffix marks a **NON-SETTLING REGION**
— a method (and everything it transitively calls) that must not settle — **NOT** merely "the core half of a public/core
pair". Precedent: `_addInPseudoRandomPositionNoSettle` has no public twin. So gesture/lifecycle hooks that run inside a
caller-supplied settle carry it even with no public wrapper. **This plan's Phase 1 turns that suffix's promise into a
checked guarantee.** (Full convention + the deferred double-underscore idea: `docs/` memory
`fizzygum-layering-naming-tiers`; reproduced in Phase 4 here.)

**The formal "low-level" tiers — ALREADY a build-enforced definition** (`buildSystem/check-layering.js`):
```js
// a method is LOW-LEVEL (rule [A] subject: must not reach UP into the public self-flushing layer)
const isLowLevel = (name) =>
  /^raw[A-Z]/.test(name) || /^silent/.test(name) ||   // immediate mutators
  /^_/.test(name) ||                                   // any leading underscore (incl. __)
  /NoSettle$/.test(name) ||                            // the *NoSettle cores
  /Layout$/.test(name);                                // _reLayout & the layout-pass family
// the strict INNER subset (rule [E] subject: may MUTATE, never SCHEDULE)
const isImmediateMutator = (name) => /^(raw[A-Z]|silent|fullRaw)/.test(name);
```
`isLowLevel ⊃ isImmediateMutator`. These two predicates ARE the single source of truth for the tiers — do not
re-define the tiers in prose elsewhere; point at these.

---

## §2 — The existing lint harness (what you're extending)

All gates live in `Fizzygum/buildSystem/`, are plain Node line-scanners (exit 0 clean / 1 violation), and are wired
into `build_it_please.sh` in this order, each behind `if ! $noSyntaxCheck`, each gated on `$?` with an explicit
`exit 1` on failure (grep `build_it_please.sh` for `check-`):

| gate | file | what it enforces | ratchet mechanism |
|---|---|---|---|
| syntax | `check-coffee-syntax.js` | CoffeeScript parse errors (fragmented compile, the faithful way) | — |
| **layering** | **`check-layering.js`** | **flow soundness — rules [A]–[F] (below). THE FILE YOU EXTEND.** | per-method `# layout-apply-sanctioned: <why>` ([F]) |
| dead-method | `check-dead-methods.js` | a method with no callers (across src + the tests' `.js`) | allowlist `dead-method-allowlist.txt`; fails only on a NEW dead method |
| stinks | `check-stinks.js` | named smells driven to a baseline COUNT | per-smell baseline; fails only on EXCEEDING it. `settle-batch-with-core` baseline 0 (hard rule) |
| thin-wrap | `check-thin-wraps.js` | a public method owning a `_<name>NoSettle` twin is the ONE canonical wrap | per-method `# thin-wrap-exempt: <reason>`; SKIPS a twinless `*NoSettle` (`:57` `if (!byName.has(base)) continue`) |

**Two ratchet patterns to imitate:** (a) **baseline/allowlist** (dead-method, stinks) — record the current count,
fail on regression, drive the baseline down over time; (b) **per-method in-code marker** (`# layout-apply-sanctioned`,
`# thin-wrap-exempt`) — the justification lives AT the method, no central allowlist. New rules should use one of these
so they can land green on today's tree and tighten incrementally.

**`check-layering.js` internals you will reuse (read the file; ~280 lines):**
- `stripLine(line, state)` — strips `#` comments + string literals (', ", ''', """, `) carrying multi-line state, so a
  call-regex never matches a method name in a throw-message or comment. **Reuse this for any new call detection.**
- `METHOD_HEADER = /^  ([A-Za-z_]\w*): (\(.*?\) )?[-=]>/` — a 2-space-indent class method header. Methods are grouped
  by walking lines between headers (dedent / next 2-space property ends a method).
- Call detection keys off a leading `@`/`.` + the lowercase public name: `PUB_CALL` matches `@setExtent`/`.fullMoveTo`
  but NOT `@rawSetExtent` (the `raw`/`silent` word sits between the `@` and the capitalised verb). This is why the
  naming convention and the lint are co-designed.
- The rules, today:
  - **[A]** an `isLowLevel(method)` must not call a PUBLIC geometry setter (`setExtent`/`fullMoveTo`/`setBounds`/
    `setWidth`/`setHeight`), a SINGLE-settling text setter (`setText`/`setFontSize`/`setFontName`/`toggleShowBlanks`/
    `toggleWeight`/`toggleItalic`/`toggleIsPassword`), or `recalculateLayouts`.
  - **[B]** `recalculateLayouts()` may be called ONLY from `doOneCycle` / `_settleLayoutsAfter` /
    `_settleLayoutsAfterBatch` (the `RECALC_WHITELIST`).
  - **[C]** a public geometry setter must not call another public geometry setter (would flush twice).
  - **[D]** a SystemTest macro (`Fizzygum-tests/tests/**/*_automationCommands.js`) must not call a `_private` method
    (`MACRO_FORBIDDEN_CALL = /[@.]\s*(_[A-Za-z]\w*)\b/`). *Planned tightening to also forbid raw/silent/fullRaw — Phase 3.*
  - **[E]** an `isImmediateMutator(method)` (`raw*`/`silent*`/`fullRaw*`) must not call `_invalidateLayout` (mutate,
    never schedule). The runtime twin is the `FLOWRULE_VIOLATION` throw.
  - **[F]** a method that is NEITHER low-level NOR an immediate mutator (a handler/menu-action/gesture/constructor)
    must not call a container-refit apply (`_reLayoutChildren`/`_positionAndResizeChildren`/`_reLayoutScrollbars`/
    `_reLayout`) off-settle, unless the method carries a `# layout-apply-sanctioned: <why>` line.

**THE GAP this plan closes.** Rule [A] forbids low-level code from calling the **5 geometry setters + the text setters
+ recalc** — i.e. a *closed, hand-listed* set, and only on a DIRECT call. It does NOT forbid a low-level/`*NoSettle`
method from calling a **structural self-settling wrapper** (`add`, `addMany`, `addAsSiblingAfterMe`, `destroy`,
`close`, `fullDestroy`, `collapse`, `unCollapse`, `buildAndConnectChildren`, `createReference`, …) — every one of which
self-settles via `_settleLayoutsAfter` and would re-enter the flush + hit the runtime throw on an attached receiver.
Nor does [A] follow calls TRANSITIVELY. So the "cores call cores" discipline is, today, **convention enforced by a
runtime throw on tested paths** — exactly the kind of thing this campaign turns into a gate.

---

## §3 — The ratchets (phased; do in order, each lands green)

### Phase 1 — the `*NoSettle` / low-level **transitive no-settle** lint (rule [G]) — THE CENTREPIECE

**Goal.** A low-level method (`isLowLevel`, which includes every `*NoSettle` core and every gesture hook) must not, by
any call path, reach a **settling** method on what could be an attached widget. Make the runtime throw at
`Widget.coffee:813` an exhaustive BUILD-time guarantee.

**Definition — the "settling set" S (computed, not hand-listed).** A method NAME is *settling* if it can cause a
flush. Compute S as a **name-based backward-reachability fixpoint** over the method-call graph extracted from src:
1. **Seed** S with: the 5 public geometry setters, the 7 single-settling text setters, `recalculateLayouts`, AND every
   method whose body (comment/string-stripped) contains a call to `@_settleLayoutsAfter`/`@_settleLayoutsAfterBatch`
   (these are the public self-settling wrappers — `add`, `destroy`, `close`, `fullDestroy`, `collapse`, … — discovered
   structurally, so you never hand-maintain the list).
2. **Iterate to fixpoint:** add any method `M` (by name) that calls (by name, `@x`/`.x`/`x …`) a method already in S,
   UNLESS `M` is itself a settle tier (`_settleLayoutsAfter`/`_settleLayoutsAfterBatch` — they ARE the flush, they
   don't "leak" it) or `doOneCycle`. Repeat until S stops growing.
3. S now over-approximates "names that can lead to a settle." (Over-approximation is by NAME: if ANY override named
   `foo` settles, `foo ∈ S`. That is SAFE for a forbid rule — worst case a false positive, handled by a marker.)

**The rule [G].** For each method `m` with `isLowLevel(m.name)` that is NOT a settle tier: if `m` calls (by name) any
method in S → **violation**, unless `m` carries `# nosettle-sanctioned: <why>` in its comment block (the [F]-style
marker; reuse the same scan). Message: ``[G] non-settling method `m` reaches settling `<callee>` (transitively via S)
— route through the *NoSettle core / raw setter, or mark `# nosettle-sanctioned: <why>`.``

**Why this is sound-by-induction.** If every low-level method is proven (by [G]) to call only non-settling names, then
a `*NoSettle` core's whole reachable subgraph is non-settling → it cannot settle. [G] subsumes the DIRECT [A] checks
(S ⊇ the geometry/text/recalc seeds) AND adds the structural-wrapper + transitive coverage [A] lacks. Keep [A] too (it
gives a sharper message for the common direct case); [G] is the closure.

**Implementation sketch (extend `check-layering.js`, ~80–120 new lines):**
- A FIRST pass over all files builds two maps: `calls: methodName → Set<calleeName>` (every `[@.]\s*(\w+)` in the
  stripped body — reuse `stripLine`) and `seeds` (per the seed rule). NB this is GLOBAL by name (collapses overrides
  across classes) — intentional, for the safe over-approximation.
- Compute S by fixpoint from `seeds` over the REVERSE of `calls` (callerOf). Cap iterations (e.g. 1000) defensively.
- SECOND pass = the existing per-method scanner; add the [G] check inside the `isLowLevel(method)` branch using S +
  the `# nosettle-sanctioned` marker (mirror the `methodMarked` logic that rule [F] already uses).
- Print `S.size` and the [G] count in the gate's summary line for visibility.

**Landing it green (CRITICAL — the tree is ALREADY clean per the runtime throw, but the lint over-approximates):**
1. Implement, run `./fg build`. Triage EVERY [G] hit:
   - a genuine leak the throw hasn't exercised → **fix the code** (route to the core); this is a real win.
   - a false positive from name-collision over-approximation (the called override truly doesn't settle, but a
     same-named method elsewhere does) → add `# nosettle-sanctioned: <why, incl. which override is actually reached>`.
   - a call to a method that's in S only because S is too coarse (e.g. a query that shares a name) → consider refining
     the seed/Set, but PREFER the marker over a clever exception (keep the lint simple).
2. The gate must end at **0 unmarked [G] violations** on `master` before you commit. Record the marker count.
3. Because this can FORCE code reroutes (core-ification), run the FULL gauntlet + a dpr2 torture soak after any code
   change, exactly like a behavioural convert (a reroute to a `*NoSettle` core is byte-identical only if the core does
   the same mutation minus the settle — verify).

**Risks / judgement calls (decide and document inline):**
- **Over-approximation noise.** If S balloons and [G] flags dozens of benign calls, the rule is too coarse to be
  useful. Mitigation tried first: exclude obvious pure QUERIES from propagation (a method that NEVER mutates — but you
  can't cheaply prove that). Pragmatic stance: if marker count > ~15 the design needs a rethink (maybe restrict [G] to
  *direct* calls to the structural-wrapper set — a strictly weaker but still-valuable ratchet, see the fallback).
- **FALLBACK if transitive proves intractable:** ship the *direct* half only — extend rule [A]'s forbidden set from
  "5 geometry setters + text setters + recalc" to "+ every structurally-discovered public self-settling wrapper"
  (seed-set S₀, no fixpoint). That alone closes the biggest real gap (`*NoSettle` calling `@add`/`@close`/`@destroy`)
  with ZERO call-graph complexity and near-zero false positives. The transitive closure is the ideal; the direct
  structural-wrapper extension is the high-value 80%. **Prefer to ship the direct extension first as Phase 1a, then
  attempt the transitive closure as Phase 1b** — 1a is low-risk and independently valuable.

**Definition of done (Phase 1):** `./fg build` green with rule [G] (or [1a] direct) active; marker count recorded in
the gate header + this doc; any forced reroutes verified byte-identical (gauntlet + torture); the runtime throw at
`Widget.coffee:813` updated-comment to note "now statically closed by rule [G]" (it currently says "the runtime
backstop").

---

### Phase 2 — rule [E] completeness: every immediate mutator is NAMED so the lint sees it

**Goal.** Rule [E] (`isImmediateMutator` must not `_invalidateLayout`) only fires on methods NAMED `raw*`/`silent*`/
`fullRaw*`. An immediate geometry mutator with an *innocent* name (e.g. a hypothetical `moveBy`/`resizeInPlace` that
sets geometry raw) escapes [E] silently — a coverage hole, not a false negative the throw would always catch (the
throw only fires if that method actually invalidates on a tested path).

**Do.**
1. Census: list every method that writes geometry immediately (greps: `rawSet`, `silent`, `fullRaw`, and—​to find the
   escapees—​methods that assign `@bounds`/`@_extent`/call `breakNumberOfRawMovesAndResizesCaches` or
   `_reFitContainerAfterRawGeometryChange` but are NOT named `raw*/silent*/fullRaw*`). The seam helper
   `_reFitContainerAfterRawGeometryChange` is reached by the raw setters — its callers are the immediate-mutator
   surface; confirm each caller is `raw*/silent*/fullRaw*` named.
2. For each escapee: **rename it** to the readable `raw*`/`silent*`/`fullRaw*` form (which ALSO makes the lint catch it
   — the fix and the coverage are the same act), OR, if a rename is genuinely wrong, extend `isImmediateMutator` with
   an explicit name + a comment. **Prefer rename** (consistency with the convention).
3. A rename of a Widget-base method may shift an inspected member list → benign recapture; verify by pixels.

**Definition of done:** a documented census showing the immediate-mutator set == exactly what `isImmediateMutator`
matches (no escapees), `./fg build` green, any renames verified.

---

### Phase 3 — rule [D] tightening: macros forbidden from the raw/silent/fullRaw API too

**Context.** Rule [D] forbids SystemTest macros from calling `_private` methods. `check-layering.js`'s own comment
(near `MACRO_FORBIDDEN_CALL`) records the PLANNED tightening: *"at the END of the deferred-layout plan [the raw/silent/
fullRaw setters] get public self-settling alternatives and this rule tightens to forbid them too (raw|silent|fullRaw)."*

**Do — but ASSESS the precondition first (it may not hold yet).**
1. Audit macro use of `rawSet*`/`fullRaw*`/`silent*` across `Fizzygum-tests/tests/**/*_automationCommands.js`. The
   lint comment notes these are "needed now" for construction-time measure-and-size read-back.
2. For each remaining macro use, confirm a PUBLIC self-settling alternative now exists (e.g. `setExtent`/`fullMoveTo`).
   If yes → migrate the macro, then extend `MACRO_FORBIDDEN_CALL` to also match `/[@.]\s*(raw[A-Z]\w*|silent\w*|fullRaw\w*)/`.
   If some have NO public alternative → **do NOT tighten**; record which, and why, here. Premature tightening would
   force macros into worse patterns. This phase is GATED on the precondition; it is fine to land it as "assessed, not
   yet ripe" with the blocking list.

**Definition of done:** either [D] tightened + macros migrated + `./fg build`+`./fg suite` green, OR a written
"not-yet-ripe" assessment listing the blocking raw/silent macro uses and the missing public alternatives.

---

### Phase 4 — (DEFERRED, optional) encode the tier in the underscore PREFIX

**The idea (owner is convinced long-term; PARKED as low-priority churn).** `isLowLevel`/`isImmediateMutator` are
understood but not *instant* to apply by eye, and immediate mutators are *private yet lack a leading `_`*
(`rawSetExtent` reads like a public method). Encode the tier visually: e.g. a leading `_` on the immediate mutators,
or `__` for the lowest tier.

**Why it is DEFERRED, not rejected (the reasoning, so a cold session doesn't re-litigate):**
- `raw`/`silent`/`fullRaw` already spell the tier in ENGLISH and the lint already keys both its classification (:67)
  and its public-vs-low-level call detection (:31) off those words → `__` buys ZERO new enforcement (`/^_/` already
  folds `__` into low-level).
- It would *flatten* a distinction the words make (`_invalidateLayout` schedules—allowed; `rawSetExtent` mutates—may
  not schedule; both share `_`) — the disambiguator is the WORD, which the lint reads.
- High churn (hundreds of call sites + serialization/inspector exposure) for a readability-only gain.

**Do — ONLY if the user decides the readability cost outweighs the churn.** Then: pick the scheme (recommend a single
leading `_` on the immediate mutators so they read private, NOT a blanket `__`), do it as a mechanical per-name sed
sweep (BSD sed, no `\b`; verify 0 un-renamed remain), update `isImmediateMutator`/`isLowLevel` if the regex anchor
changes, gauntlet + torture, recapture any inspector shifts. Default action this phase: **leave parked; keep this
section as the decision record.** (Memory: `fizzygum-layering-naming-tiers`.)

---

### Phase 5 — (GATED) the "end-of-cycle-sanctioned" allowlist lint

**The eventual gate** the drawdown campaign points to (`end-of-cycle-flush-drawdown-plan.md` §9): a `check-layering.js`
extension that WARNS when a widget reaches the end-of-cycle flush from a method NOT carrying
`# end-of-cycle-sanctioned: <why>` — mirroring the `# layout-apply-sanctioned` [F] marker. It makes "what is allowed to
defer to the per-frame flush" a checked allowlist.

**GATED — do NOT build this yet.** As of 2026-06-25 the owner **retracted all "LEAVE" verdicts** (the set that would
populate this allowlist) — every formerly-allowlisted item is now `OPEN — re-probe` (`end-of-cycle-flush-inventory.md`
§4 banner). Building the allowlist gate before that set is RE-PROBED and genuinely earned would just rubber-stamp the
cavalier leaves this campaign is dismantling. **Precondition:** the OPEN set (hover, during-paint, setMaxDim, soft-wrap,
SwitchButton-collapse, childRemoved) is each resolved to convert/eliminate/PROVEN-leave. Only the proven-leave residue
earns an `# end-of-cycle-sanctioned` marker and the gate. Keep this section as the spec; revisit when the drawdown
inventory has no `OPEN — re-probe` rows left.

---

## §4 — Single source of truth for the tiers (lightweight, do alongside Phase 1)

Make the convention docs POINT at the predicates instead of re-describing them (so they can't drift from what's
enforced): in `docs/layout-system-architecture-assessment.md` and the drawdown docs, where "low-level"/"immediate
mutator" are defined in prose, add *"≝ whatever `buildSystem/check-layering.js` `isLowLevel()` / `isImmediateMutator()`
match"*. Memory `fizzygum-layering-naming-tiers` already records this — mirror it in-repo.

---

## §5 — Verification protocol (per phase)

1. **Gate self-test:** `./fg build` → the new gate prints its summary and **0 unmarked violations**. Temporarily inject
   a known violation (a `*NoSettle` method calling `@add` in a scratch copy) and confirm the gate FAILS loudly + aborts
   the build — a lint that can't fail is worthless. Revert the injection.
2. **Escape hatch intact:** `./build_it_please.sh --noSyntaxCheck` still builds (the new gate respects the shared flag).
3. **No behaviour drift from gate-only changes:** a pure gate edit cannot change a screenshot — but if a phase FORCED
   source reroutes (Phase 1 core-ification, Phase 2 renames), run `./fg gauntlet` (165/165 byte-identical across
   dpr1/dpr2/WebKit/apps) + a dpr2 torture soak (`cd /abs/Fizzygum-tests && node scripts/torture-headless.js --dprs=2
   --speeds=fastest --shards=4 --minutes=10`; shards=8 thrashes this box). Benign inspector recaptures → `fg recapture`.
4. **Homepage build:** `./fg build` with `--homepage` (gates that scan only `src/` still run; the test-.js gate +
   dead-method gate self-skip when tests are absent) — confirm the new gate doesn't break the tests-stripped build.

---

## §6 — Sequencing, risks, rollback

**Order:** Phase 1a (direct structural-wrapper extension — low risk, high value) → Phase 1b (transitive closure —
attempt, fall back to 1a if too noisy) → Phase 2 (rule [E] completeness) → Phase 3 (rule [D] assess/tighten) → §4 docs
pointer. Phase 4 + Phase 5 stay parked behind their preconditions. **Commit per phase** (review-driven) with a message
naming the rule + the marker count + any forced reroutes; WAIT for approval before push.

**Risks:**
- *A new gate that's too noisy* erodes trust in ALL gates → keep each rule simple, prefer a per-method marker over a
  clever exception, and if Phase 1b's false-positive rate is high, ship 1a and stop.
- *A forced reroute changes behaviour* → core-ification is byte-identical ONLY if the core is the same mutation minus
  the settle; verify with gauntlet + torture, never just dpr1.
- *Over-fitting the lint to today's tree* → seed S structurally (scan for `_settleLayoutsAfter` callers), don't
  hand-list, so it stays correct as the codebase changes.

**Rollback:** every gate is one self-contained `buildSystem/*.js` (+ its `build_it_please.sh` wiring block); revert the
file + the ~10-line wiring block. Source reroutes are ordinary `git revert`. No data migration, no serialized state.

---

## Appendix A — file:line anchors (grep the symbol; numbers drift)

- `Fizzygum/buildSystem/check-layering.js` — rules [A]–[F]; `isLowLevel` ~:66, `isImmediateMutator` ~:95;
  `PUBLIC_SETTERS`/`TEXT_SETTERS`/`RECALC_WHITELIST` ~:43–64; `stripLine` ~:112; `METHOD_HEADER` ~:158; the per-file
  scanner `checkFile` ~:160; the `# layout-apply-sanctioned` marker logic ~:177/211.
- `Fizzygum/buildSystem/check-thin-wraps.js` — twinless skip `:57`; `# thin-wrap-exempt` `:15`/`:32`.
- `Fizzygum/buildSystem/check-dead-methods.js` + `dead-method-allowlist.txt`; `check-stinks.js` (baselines).
- `Fizzygum/build_it_please.sh` — gate wiring ~:255–345 (syntax/layering/dead/stinks/thin-wrap), each `if !
  $noSyntaxCheck` + `$?`-gated `exit 1`.
- `Fizzygum/src/basic-widgets/Widget.coffee` — `_settleLayoutsAfter` ~:792 (orphan guard ~:805, **the throw ~:813**,
  batch guard ~:819); `_settleLayoutsAfterBatch` ~:843 (0 callers, allowlisted); `_invalidateLayout` FLOWRULE throw
  ~:3848.

## Appendix B — companion docs (context, not prerequisites)

- `docs/end-of-cycle-flush-drawdown-plan.md` — the layout-flush drawdown campaign (the invariant's motivation; §2 the
  three-fault principle; §9 the end-of-cycle-sanctioned gate this plan's Phase 5 specs).
- `docs/end-of-cycle-flush-inventory.md` — the current by-action audit + the retracted-LEAVE banner (Phase 5 gate).
- `docs/layout-system-architecture-assessment.md` — the flush model + the invariant in depth.
- `docs/deferred-layout-OVERVIEW.md` / `deferred-layout-refit-and-add-design.md` — the deferred-layout campaign that
  built the settle tiers + rule [E]/[F]; D3 (the orphan guard) is referenced by `_settleLayoutsAfter`.
- Memory `fizzygum-layering-naming-tiers` — the `NoSettle` convention + the deferred `__` decision.

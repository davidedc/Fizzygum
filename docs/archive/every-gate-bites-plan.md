# Every gate's rule bites — a standing proof for each gate, and a build that holds the line

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.** Status: AUTHORED 2026-11-07
against Fizzygum `c619e504` / Fizzygum-tests `ce9e3a339` (both pushed); owner decisions D1–D4 RULED 2026-11-07 (§3,
§8.2). **CLOSED 2026-11-07** — Units 0, A–F done; the end-of-arc review's findings all fixed (§8.5); the build's census
holds 53 launched gates, each with a rule registry and a proof that plants every rule; closing gauntlet 20/20 (§8.5).
Ledger: §8.

**Mandate — elimination, not inventory.** When this arc closes:
- every RULE of every gate that the build or an `fg gauntlet` leg runs is either proven to bite by a standing
  self-test that RUNS THE GATE on a planted violation, or carries a written, reviewed reason why no plant can prove it;
- the build refuses a new gate that arrives without such a proof (the meta-rule, §3 D2);
- the masks those proofs expose are fixed in the arc, the known one first: `check-unresolved-sends`'s catch-all
  definition form (§1.4);
- the five plant rails that a stray `export` can arm are closed (§1.5).

A survey that just lists the gaps is NOT a deliverable. The survey (Unit 0) only exists to size the units that close
the gaps.

---

## §0 Orientation

**The workspace.** Fizzygum is a CoffeeScript GUI framework rendered on one `<canvas>`. `Fizzygum-all/` is an umbrella
directory (not a git repo) holding three sibling repos:
- `Fizzygum/`: the source, the build and the static gates;
- `Fizzygum-tests/`: 373 SystemTests and the headless runners and audit gates;
- `Fizzygum-builds/`: generated output, never edited.

Every build and test command goes through the local wrapper `/Users/davidedellacasa/code/Fizzygum-all/fg`, always
invoked by absolute path. Run it bare to print its usage. The gate index, with each gate's blind spots, is
`Fizzygum/docs/architecture/lint-and-static-checks.md` §3. Read its §3 table and its "A gate's RULE is proven to BITE"
paragraph before Unit 0.

**The two arcs before this one.**
- `docs/archive/unrun-checks-plan.md` (closed 2026-11-06) made every check the workspace relies on actually RUN. Every
  self-test is a FILE found by name (`<subject>-selftest.js`, node tier, run by the build; `*-selftest-headless.js`,
  run by the gauntlet's `selftests` leg) through `buildSystem/lib/what-runs.js`'s naming table. `what-runs.js` also
  knows which files the build, the self-test runners and `fg` legs actually LAUNCH, and it counts invocations, not
  mentions.
- `docs/archive/bite-proofs-plan.md` (closed 2026-11-07) made eight gates' rules prove themselves at every commit
  point by running the REAL gate on a plant:
  - **static gates** (call-separation, back-buffer-memos, page-loaded-elements): `buildSystem/lib/planted-src.js`
    copies `src/` to a temp dir (107 ms), ADDS a throwaway class carrying the defect and runs the gate on the copy
    through a `--src=DIR` rail. The planted run must fail on the gate's own violation line, the control and every
    sanctioned form must pass;
  - **suite audit gates** (tier-naming, settle, revisits, storage, capstone ×2):
    `Fizzygum-tests/scripts/lib/gate-bite-proof.js` runs the gate on ONE test (`--tests=`, a private `--out=DIR`) with
    a plant injected by `PRELUDE_JS`. The planted run must exit 1 naming the plant, a blind bucket must read INVALID
    (exit 2) and the control must exit 0.

  That arc filed the question this plan answers, as its residue.

**⭐ Critical reframe 1: "has a self-test" is not "its rule is proven to bite".** Six gates have self-tests that
exercise their DECISION FUNCTIONS on in-memory fixtures (§1.1, kind **E**). Such a test proves the logic but not:
- the file walk that feeds it, or the harvest;
- the masking;
- the exit code, or the report.

The settle gate shows why that matters. Its per-callback summary had NEVER worked: its `sed` expected the fields in an
order the prelude does not emit. Only the gate-run proof saw it, because every earlier check asked the instrument and
never the gate. So the survey unit is the pair (gate, rule), and engine fixtures stay as unit tests but do not count as
proof (§3 D1).

**⭐ Critical reframe 2: writing a proof IS the audit.** A bite-proof that deletes every real definition of a method and
expects `check-unresolved-sends` to fail would PASS wrongly today for 48 names (§1.4). The plant is what exposes a
mask, so expect each unit to find something. A found mask is the arc's product, not a detour: fix it in the unit if
it is bounded, otherwise file it with its measurement.

**⭐ Critical reframe 3: the known mask cannot simply be deleted.** At least 131 class-side `@name: (…) ->` headers
(plus one-liners) and 67 headers whose parameter default holds a paren are caught ONLY by the catch-all form. Removing
it naively makes the build fail on correct code: a false FAIL, which the gate's own header ranks as the worst outcome
(§1.4). This is a design unit, not a deletion.

---

## §1 Survey — the state today (verified 2026-11-07; line numbers drift, grep the quoted names)

Proof kinds: **G** = a self-test that runs the REAL gate on a planted input. **E** = engine fixtures only (exported
functions on in-memory input). **N** = no self-test. "Rail" = how a proof can feed the gate a planted input today.

### §1.1 The 33 build gates (`Fizzygum/build_it_please.sh`, in run order; times on the real tree, idle machine)

| # | Gate (file) | Rules (see the index §3 for the text) | Proof | Rail | Time |
|---|---|---|---|---|---|
| 1 | `buildSystem/run-selftests.js` | a self-test not PROVING a pass stops the build | E (`run-selftests-selftest.js`: judge, offeredFlags) | — | ~1.7 s |
| 2 | `check-coffee-syntax.js` | parse error; member losing a name to the helper strip | N | none | 1.38 s |
| 3 | `check-shippable-coverage.js` | a `src/` dir no part claims | N | none | |
| 4 | `check-layering.js` | rules [A]–[T] (19 rules, no [S]) | N | none | 0.41 s |
| 5 | `check-invalidation-receivers.js` | `_changed`/`_fullChanged` on another widget | N | none | |
| 6 | `check-dead-methods.js` | a dead method not in the allowlist; settle-twin symmetry | E | none | 0.31 s |
| 7 | `check-hand-lists.js` | unsanctioned name list; sanction guard never runs; stale/empty sanction | E (+ `--files` plant mode, by hand) | `--files` | 0.21 s |
| 8 | `check-unresolved-sends.js` | unresolved `[@.]name(`; stale allowlist/BUILTINS entry | E | none | 0.17 s |
| 9 | `check-stinks.js` | 13 ratcheted smells (`STINKS`, each `{id, baseline, re}`) | N | none | 0.21 s |
| 10 | `check-argument-holes.js` | a bare `undefined` hole (R3) | N | none | |
| 11 | `check-menu-actions.js` | provably-wrong menu wiring (`RULE <x> FAIL`) | N | none | 0.45 s |
| 12 | `check-thin-wraps.js` | thin wrap of a `_…NoSettle` twin | N | none | |
| 13 | `check-trailing-whitespace.js` | `/\S[ \t]+$/` | N | none | 0.04 s |
| 14 | `check-scheduled-checks.js` | overdue `# CHECK AFTER <date>` | N | none | |
| 15 | `check-stringified-scripts.js` | `new ScriptWdgt """…"""` in core | N | none | |
| 16 | `check-region-markers.js` [tombstone] | `# »>>` at zero | N | none | |
| 17 | `check-source-vault.js` [tombstone] | `window.<Name>_coffeSource` at zero | N | none | |
| 18 | `check-whole-file-markers.js` [tombstone] | per-file exclusion comments at zero | N | none | |
| 19 | `check-part-edges.js` | unguarded core → part reference (class, installed member); unused `requires` | E | none | 1.20 s |
| 20 | `check-constructors-build.js` | a constructor building its own children | N | none | |
| 21 | `check-call-separation.js` | [S], [U] | **G** | `--src=` | |
| 22 | `check-relayout-bounds-first.js` | `_reLayout` applies its bounds first | N | none | |
| 23 | `census-widget-conformance.js --gate` | two objective facets, ratcheted | N | none | |
| 24 | `check-back-buffer-memos.js` | back-buffer memo field | **G** | `--src=` | |
| 25 | `check-page-loaded-elements.js` | page-element clauses (4) | **G** | `--src=` | |
| 26 | `check-relayout-repaints.js` [tombstone] | the retired suppression verbs | N | none | |
| 27 | `check-raw-pointer-reads.js` | raw pointer reads in a handler | N | none | |
| 28 | `check-plane-discipline.js` | three paint-time scroll rules | N | none | 0.12 s |
| 29 | `Fizzygum-tests/scripts/check-tests-syntax.js` | JS syntax of the tests' `.js` | N | none | |
| 30 | `…/check-macro-source-discipline.js` | three macro-source rules | E (acceptance corpus, no spawn) | none | |
| 31 | `…/check-refs.js` (structural) | >1 `dataHash` per key; orphan `.js`/`.png` | N | none | |
| 32 | `…/check-visualisations.js` | dead `<img src>`; (strict) page ≠ generated | **G** (spawns the gate on fixture dirs) | `--tests-dir=` | |
| 33 | `…/aim-census.js --tables-only` | the aim census's tables | N | `AIM_CENSUS_SRC` env (⚠ §1.5) | |

Tally: **G 4 · E 6 · N 23.** The blank time cells and the per-rule split are Unit 0's to fill. Commands to time a gate:
`cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum && perl -MTime::HiRes=time -e '$t=time; system("node buildSystem/$ARGV[0].js >/dev/null 2>&1"); printf "%.2fs\n", time-$t' check-layering`.

### §1.2 The 20 gauntlet legs (`fg`'s `run_leg`; the build leg is §1.1)

| Leg | Runner | Rule | Proof | Rail |
|---|---|---|---|---|
| dpr1 / dpr2 / webkit / finger | `run-all-headless.js` | every screenshot matches; no GATE token (`lib/gate-tokens.js`) | E for pieces (`lib/gate-tokens-selftest.js`, `lib/suite-summary-selftest.js`), **no end-to-end** | `--tests=` + `PRELUDE_JS` |
| apps | `smoke-apps-headless.js` | every app opens clean | N | none |
| parts | `parts-lazy-load` / `parts-snapshot-load` / `parts-lazy-icons` | the lazy part paths | N | none |
| menusweep | `menu-click-sweep-headless.js` | no menu action throws; `opensSubmenu` truthful | N (by hand) | `PRELUDE_JS` (⚠ §1.5) |
| pinsweep | `pin-sweep-headless.js` | every advertised pin resolves; `announces` fixtures | N (by hand) | `PRELUDE_JS` (⚠) |
| graph | `graph-liveness-headless.js` | the widget-graph liveness contract | N | none |
| selftests | `run-selftests.js --headless` | — (the runner) | E | — |
| paint | `run-paint-audit.js` | paint truthfulness | N | none known |
| tiernaming / settle / capstone ×2 / revisits / storage | the bite-proofs arc's gates | their rules | **G** | `--tests=` `--out=` `PRELUDE_JS` |
| refs | `check-refs.js --pixels`; `check-visualisations.js --strict`; `Fizzygum/buildSystem/check-doc-narration.js` | ref re-hash; page freshness; docs ratchet | N; G (if its self-test covers `--strict`, Unit 0 confirms); N | `--tests-dir=` for visualisations only |
| census | `staleness-census.js` | arrange idempotence | N (by hand) | `PRELUDE_JS` (⚠) |
| serialization | `serialization-roundtrip-headless.js` + `-file-roundtrip-` | the round-trip checks; an `EXPECTATIONS` name no backend reports is a MISMATCH | partial (that self-check) | `PRELUDE_JS` (⚠) |
| vmtruth | `vm-truth-gate.js` | destroyed widgets collectible; heap-floor ceiling | N for the gate (`heap-forensics-selftest-headless.js` proves the forensic TOOL) | `--` runner args (Unit 0 confirms `--tests=`) |

The `selftests` leg ran 146 s in-wave at the last gauntlet. Wave A's longest leg was dpr2 at 211 s, so new headless
proofs have about 65 s of headroom at `HEADLESS_POOL = 3` before they lengthen the gauntlet.

### §1.3 The reusable machinery (already committed)

- `buildSystem/lib/planted-src.js`: `plantedSrc()` gives `{dir, plant(rel, text), unplant(rel)}`, a src copy removed
  at exit, with stale copies older than 1 h swept. `runGate(script, srcDir)` gives `{status, out, why}`.
- The `--src=DIR` rail on gates 21, 24 and 25. Each refuses unknown arguments and positional arguments via
  `buildSystem/lib/cli-args.js`'s `rejectUnknownArgs`.
- `Fizzygum-tests/scripts/lib/gate-bite-proof.js` exports:
  - `TEST` (`SystemTest_macroAnalogClockInspectEdit`);
  - `shellGate(rel)` and `nodeGate(rel)`;
  - `runGate(gate, {plant})`: a fresh `--out=` dir, `PRELUDE_JS` set or deleted, `FIZZYGUM_KEEP_STALE_BROWSERS=1`;
  - `UNOBSERVED_BUCKET`, a blind plant, `audit-preludes/unobserved-bucket-plant.js`.
- Plant conventions (the bite-proofs plan §5):
  - confined to `TEST` and bounded;
  - order-independent: hook a method the prelude does not wrap, inside a frame it does;
  - a plant whose hook is gone prints `PLANT_NOT_APPLIED` 60 frames after the world appears.
- `buildSystem/run-selftests.js` pools files (node 4, headless 3), reports in discovery order and kills a timed-out
  file's whole process tree.

### §1.4 The known mask: `check-unresolved-sends`'s catch-all definition form

The gate reads a paren-call `[@.]name(` as resolved when ANY file defines `name`. Definitions come from `DEF_FORMS`
in `buildSystem/lib/name-definitions.js`. `check-part-edges.js` shares that file: "one implementor harvest, not two".
Form 6 is the catch-all, `/^\s*@?([A-Za-z_$][\w$]*)\s*[:=]/`, "ANY other property key — over-approximate ON PURPOSE".
The gate's own header lists the consequence as a KNOWN GAP: a data key or local of a name (`close:` in a theme table)
"keeps a call of it resolved after every real method of that name is gone".

Measured 2026-11-07 (586 `.coffee` files in `src/` + the harness, 8019 harvested call sites; method in Appendix A):
- **62 sent names have a data-key or local-variable definition** (form 6 only, not a header), covering 2388 sites:
  - **48 of them also have a callable definition** (2337 sites). This is the mask: delete every real method of one
    of these and the gate stays green. Examples: `close` (15 sites, data key `close: theme.barControlGlyphSize` in
    `FrameWdgt`), `get` (28), `clear` (39; `clear = mI` in `CurledArrowsSquareIconAppearance`), `entries` (1;
    `entries = []` in `Serializer`).
  - **14 of them resolve ONLY through such a definition today** (51 sites), in four classes:
    - (i) **one-line class-side methods**, `@name: -> …` with the body on the same line. Real definitions that no
      callable form covers: `candidateOutlineStyle`, `reluctantOutlineStyle`, `resizeTargetOutlineStyle`
      (`HighlighterWdgt`), `standardDesktopIconExtent` (`WidgetHolderWithCaptionWdgt`), `canReplaySourceEdits`
      (`SourceEditsRegistry`).
    - (ii) **a header continued with a backslash**: `addCheckMarksAndUpdateCodeAndNotifyChange: \` (`LCLCodeCompiler`).
    - (iii) **a property that holds a function**: `overridingContextMenu` (`Widget` declares it `undefined`,
      `TextWdgt` assigns `@evaluationMenu`) and `drawFunction` (`LCLProgramRunner`, compiled code). These are
      genuinely dynamic sends.
    - (iv) **platform methods missing from `BUILTINS`**: `test`, `match`, `shift`, `clip`, `focus`, `from`. Each is
      "resolved" only because some Fizzygum data key shares its name.
- **Headers that only the catch-all catches**: 131 multi-line class-side headers `@name: (…) ->` plus the one-liners
  of class (i), and 67 headers whose parameter default holds a paren (`processDoubleClick: (w = @topWdgtUnderPointer()) ->`;
  forms 1–2 stop at the first `)`).
- **Sibling, unmeasured:** form 5 (a bare local `helper = ->`) masks the same way, because "no receiver typing" means
  a local closure resolves a call anywhere. Unit C sizes it and rules on it.

### §1.5 Plant rails that a stray `export` arms

- `Fizzygum-tests/scripts/lib/prelude-from-env.js` installs `PRELUDE_JS` into every page the rig boots, whenever the
  variable is set; the only signal is a logged `prelude:` line. Its users are `menu-click-sweep-headless.js`,
  `pin-sweep-headless.js`, `staleness-census.js`, `serialization-roundtrip-headless.js` and `smoke-boot-headless.js`.
  The first four are gauntlet legs. The bite-proofs arc ruled this exact hazard real for the suite runner (its review
  R6), and `run-all-headless.js` now honours `PRELUDE_JS` only beside `--tests`, refusing with exit 2 otherwise. The
  five rigs never got that rule.
- `aim-census.js` reads `AIM_CENSUS_SRC=<dir>` in place of `Fizzygum/src`, and it is build gate 33. A stray export
  makes the BUILD check a scratch copy. The static gates spell the same rail `--src=DIR`.

---

## §2 Why it is shaped this way

The gates were written one at a time, across about a year of arcs. Each one was proven at authoring by a plant made
once, by hand: a recipe in its header, a sentence in a commit message. Gates with intricate logic grew engine
fixtures; tombstones and one-regex gates grew nothing, because they "obviously work". Nothing required a standing
proof, and nothing could have made one cheaply: the rails (`--src=`, `--tests=`, `--out=`, `planted-src.js`,
`gate-bite-proof.js`) only arrived with the bite-proofs arc, and only for its eight gates. The unresolved-sends
catch-all is deliberate. The gate's header ("THE SOUNDNESS TRADE") ranks a false FAIL above a miss, and form 6 was the
cheapest way to never false-fail on a definition form the harvest had not learned. Its cost, the mask, was written
down as a known gap and never measured until now.

## §3 The argument, and the owner decisions (ONE round, before Unit 0; recommendation first)

**Why now, and why this shape.** The machinery exists and is proven, so a static bite-proof is now about 40 lines: a
planted class, a violation regex, a control. The last arc showed the payoff is not hypothetical, since the proof found
a defect on its first run. A rule that cannot be seen failing is a hypothesis. 23 of 33 build gates and about 10
gauntlet legs are hypotheses today. The meta-rule must be DERIVED (from `lib/what-runs.js`, which already knows what
the build and `fg` launch), never a hand-kept "gate → proof" table: the hand-kept-lists arcs showed such a table rots
silently.

**Two constraints, stated rather than asked (override them in the round if you disagree):**
- **Scope = everything in §1.1 and §1.2**, build gates first (cheap, node tier, every build) and gauntlet legs second.
  The mandate rules out "build gates only".
- **Budgets.**
  - The build's node-tier self-test step (1.7 s today) stays **≤ 6 s** on an idle machine. Each static proof does
    ONE planted run carrying all of its rules' plants at once (each plant a distinct throwaway class, each violation
    matched on its own line) plus one control run. Sanctioned or exempt forms ride inside the planted run when they
    cannot interact.
  - The `selftests` leg stays **≤ wave A's longest leg** (about 211 s). Past that, raise `HEADLESS_POOL` or split
    the leg, with a measurement either way.

**D1. What counts as "proven to bite"?**
- **(a) Recommended.** A standing self-test that RUNS THE GATE on a planted input, per RULE. It checks the gate's exit
  code AND its own violation line naming the plant. The control must pass, and each sanctioned or exempt form must
  pass. Engine fixtures stay as unit tests but do not count. Why: the settle summary defect was invisible to engine
  tests.
- (b) Engine fixtures count where they exist. The 6 E-kind gates are then done, but the harvest, the walk and the exit
  code stay unproven.
- (c) Per GATE, not per rule: one plant per gate. Cheaper, but a gate with 19 rules (layering) proves one of them.

**D2. The meta-rule: does the build require it?**
- **(a) Recommended. A derived, file-level check inside `run-selftests.js`.** Every gate in the run set of
  `lib/what-runs.js` (what the build, the self-test runners and `fg`'s legs LAUNCH) must have a self-test that itself
  LAUNCHES that gate (what-runs' invocation test, not a mention). A gate one of whose rules cannot be planted states
  why in its header, in a form the check reads. Per-rule coverage is held by each proof's cases and by the end-of-arc
  review.
- (b) (a), plus per-rule coverage derived mechanically: every rule token a gate can emit (`RULE [S]`, a stink id,
  `RULE <x> FAIL`), read from the gate's source, must appear in its proof's expectations. Stronger, but it couples the
  check to each gate's report format. Unit 0 sizes it.
- (c) No meta-check. A "proof" column in the index is kept by hand. A hand-kept list, and it rots.

**D3. One spelling for "run on a plant" (the §1.5 rails).**
- **(a) Recommended. Flags only.**
  - `--src=DIR` for every src-reading gate, `aim-census.js` included (`AIM_CENSUS_SRC` retired).
  - `--prelude=FILE` for every browser rig. `PRELUDE_JS` and `lib/prelude-from-env.js`'s env read are retired
    everywhere, `run-all-headless.js` included. `gate-bite-proof.js`, `parse_gate_args` and the three shell gates
    learn to pass `--prelude=` through.

  A flag cannot leak, and there is one of each thing. Cost: about 10 files in the tests repo, and the five
  just-landed suite proofs re-run.
- (b) Keep the env var, honoured only beside an explicit flag (`--tests` in the suite runner as today; a new
  `--plant` on the five rigs). Two spellings stay.
- (c) Leave the five rigs as they are. Rejected by the mandate, since a stray export arms four gauntlet legs.

**D4. The unresolved-sends mask (§1.4).**
- **(a) Recommended. A callable-only harvest.** Drop form 6. Teach the harvest:
  - a class-side header form (`@name:` with an arrow anywhere on the line, so one-liners count);
  - a header whose parameter list is read with a paren counter rather than a regex (the 67);
  - the backslash continuation.

  Put the six platform names in `BUILTINS`, which is a fact about the platform. Put the property-held closures
  (`overridingContextMenu`, `drawFunction`) in `unresolved-sends-allowlist.txt` with reasons, as genuinely dynamic
  sends. Rule on form 5 locals with their measurement. Then the bite-proof: delete every callable definition of a name
  that also has a data key, and the gate must FAIL naming the call. `check-part-edges.js` shares the harvest, so its
  own self-test and gate are re-run, and any change in its verdicts is explained.
- (b) Keep form 6, minus keys whose value "is not a function". That needs typing the value, which is heuristic:
  `@overridingContextMenu = @evaluationMenu` is a function reference that no text test can tell from data.
- (c) Receiver typing (the gate's "v2" item §8.7). Out of scope: it is a different gate.

---

## §4 Units (each is gated before the next starts; the protocol is §5)

### Unit 0 — the per-rule survey (read-only; may be fanned out to research agents by gate family)

For every row of §1.1 and §1.2, write one ledger row per RULE into §8 here, giving:
- the rule, quoted from the gate's report;
- its current proof kind;
- the plant that would prove it (a planted class or line, or a page prelude);
- the rail it needs;
- the sanctioned forms its control must also pass;
- the gate's time;
- or "cannot be planted, because …".

Confirm each E-kind self-test really is engine-only, and confirm the two "Unit 0 confirms" cells of §1.2. Families for
fan-out:
- (F1) text and tombstone gates: 13–18, 26, 29;
- (F2) structural gates: 2–5, 10–12, 19–20, 22–23, 27–28;
- (F3) E-kind and ratchet gates: 1, 6–9, 30–31, 33, plus `check-doc-narration.js`;
- (F4) the gauntlet legs of §1.2.

Agents only read and report: no edits, no builds, no `fg`, no killing browsers. **Exit:** a ledger with no blank
cell, plus a cost estimate per unit against the §3 budgets.

### Unit A — rails (per D3)

- `--src=DIR` on every src-reading build gate that lacks it, with the same `rejectUnknownArgs` refusal (positional
  arguments refused too). Repeated mechanically per gate: read the gate's `SRC` constant and every read of it, as
  `census-public-private-calls.js`'s `runCensus({ src })` was.
- Gates that read a non-src tree get the rail for that tree: `--tests-dir=` for `check-refs.js` (like
  `check-visualisations.js`), and a docs-root rail for `check-doc-narration.js` (Unit 0 names it).
- The browser rigs' plant rail, per D3.

**Exit:**
- every gate run with no rail gives a verdict byte-identical to before (diff the output on the real tree);
- every rail refuses an unknown or empty value with exit 2;
- `fg build` passes.

### Unit B — the build gates' bite-proofs, by family (one `<gate>-selftest.js` per gate, beside the gate)

The pattern is `buildSystem/check-back-buffer-memos-selftest.js`: `plantedSrc()`, one planted run carrying every
rule's plant, a violation regex per plant matched against the gate's OWN violation line (never its summary — the last
arc's review found that "names the plant" checks matched words every summary prints), and a control run. Each
self-test uses `lib/selftest-verdict.js` so `run-selftests.js` can judge it.
- **B1 (F1)**: one plant each. For a tombstone: the retired marker, planted in a throwaway file.
- **B2 (F2)**: one plant per rule. `check-layering`'s 19 rules ride ONE planted run as 19 throwaway classes.
- **B3 (F3)**: upgrade each E-kind gate to a gate-run proof. Keep the engine fixtures. `check-stinks` gets one planted
  line per stink id: each ratchet fails on EXCEEDING its baseline, so the plant adds `baseline − current + 1`
  occurrences, computed from the gate's own count rather than hard-coded. `check-unresolved-sends` waits for Unit C.

**Exit per family:**
- each proof passes on the real tree;
- each is SEEN FAILING twice, by the neutralisation protocol of §5, step 3;
- the node tier is still within its budget (time `node buildSystem/run-selftests.js`).

### Unit C — the unresolved-sends harvest (per D4), then its bite-proof

Re-measure Appendix A first. Then:
1. change `DEF_FORMS`;
2. move the platform names into `BUILTINS`;
3. add the allowlist entries;
4. run `check-unresolved-sends.js` (it must stay green with ZERO new allowlist entries beyond the closures ruled on in
   D4);
5. run `check-part-edges.js` and both self-tests.

The bite-proof plants a src copy in which a masked name's callable definitions are removed: one whose data key
remains (`close`), with a planted call to it. It must fail naming that call. The control must pass.

### Unit D — the gauntlet legs' bite-proofs (`*-selftest-headless.js`, Fizzygum-tests)

Use the `gate-bite-proof.js` pattern wherever the runner takes `--tests=` (the suite fail-gate, vmtruth if Unit 0
confirms). Use a single-page plant through the D3 rail elsewhere (menusweep: a menu action that throws; pinsweep: a
`PinSpec` naming a missing setter; census: arrange drift; serialization: a field the serializer drops; apps, parts,
graph, paint: Unit 0's plants; refs: a temp tests dir holding one corrupted reference PNG).
- **The suite fail-gate** needs two plants on one test: a one-pixel paint shift (FAIL naming the test's image) and a
  console GATE token (FAIL naming the token). Both are run on chrome AND on webkit: the Playwright adapter is the part
  that differs, and the bite-proofs arc's only gauntlet failure was webkit-only.
- Every plant follows §1.3's conventions, including `PLANT_NOT_APPLIED`.

**Exit:** every proof is seen failing per §5 step 3, and the `selftests` leg is timed within its budget, alone and
in-wave.

### Unit E — the meta-rule (per D2)

It lives in `run-selftests.js` because that runner already discovers by name. It reads the run set from
`lib/what-runs.js`, so nothing is listed by hand. It fails the build naming each launched gate that no self-test
launches, and each exemption it cannot parse. Its own self-test: a miniature workspace (as `lib/what-runs-selftest.js`
builds one) where one gate has a proof, one has none (must fail) and one has a header exemption (must pass).
Prove the meta-check bites by removing one real proof in a scratch copy.

### Unit F — docs

- `lint-and-static-checks.md` §3: the table gains a proof column, generated by or checked against the meta-rule, never
  hand-kept. The bite-proof paragraph is restated as a rule the build enforces, and the unresolved-sends paragraph's
  known gap is removed or narrowed.
- The `CLAUDE.md` files' self-test sentences (Fizzygum, Fizzygum-tests, the local umbrella) are updated.
- `docs/BACKLOG.md`: close this item, close the §4 unresolved-sends item, and file the residue.
- Write in the present tense: no dated notes in non-chronological docs.

---

## §5 Cold-execution protocol and verification

House rules:
- `fg` only by absolute path, and a gating `fg` call is never piped;
- long operations run in the background, peeked at every ~5 min;
- a running `fg` operation owns `src/`, `tests/` and `scripts/`, and `buildSystem/` while it builds (docs and memory
  are safe);
- `.coffee` files are edited with the Edit tool only;
- Node probes and plants under development live in `Fizzygum-tests/.scratch/`;
- zsh: never `echo ====`, quote globs (`--include='*.coffee'`), write multi-line scripts as `node - <<'EOF'`;
- `fg` is local and uncommitted: back it up before editing, and record its edits in the ledger;
- never commit or push without the owner's explicit approval of THAT commit; use `git commit -F <file>`.

Steps:
1. **Orient:** run `fg status`, expect `c619e504` / `ce9e3a339` or later and clean trees. Read this plan, then the
   index §3, then `docs/archive/bite-proofs-plan.md` §5 and §9 (the plant conventions and the review lessons).
2. **The owner round:** D1–D4 in ONE `AskUserQuestion` call, with the §3 constraints stated in it.
3. **Per unit:**
   1. edit;
   2. run each new proof alone (`node buildSystem/<gate>-selftest.js`, or `node scripts/<x>-selftest-headless.js` from
      the tests repo);
   3. **see it fail twice** in a scratch copy of the proof: once with its plant replaced by the control text, once
      with its control fed the plant. A neutralisation driver like the last arc's `.scratch/bite-proofs/neutralise.js`
      is the cheap way;
   4. `fg build`;
   5. `fg presuite`.

   Before any gauntlet that follows a tests-repo runner change, also run
   `node scripts/run-all-headless.js --browser=webkit --tests=SystemTest_macroAnalogClockInspectEdit` from the tests
   repo: presuite is Chrome-only.
4. **Close:**
   1. `fg gauntlet` in the background (20/20 required; a load-flake retry is reported, not hidden);
   2. `npm run selftest` in the tests repo;
   3. `fg homepage` only if `build_it_please.sh`, `src/boot` or `src/meta` changed;
   4. ONE independent end-of-arc review: a fresh agent given the goals and the diffs, read-only;
   5. fix what it confirms, then re-gate;
   6. archive this plan with a plain `mv` to `docs/archive/` (stamp it CLOSED, add an INDEX line), and move the
      BACKLOG items into its ledger;
   7. update memory;
   8. draft the commit messages (ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and no other
      trailer) and WAIT for approval. Ask about the push separately.

## §6 Risks

- **Vacuous proofs.** A regex that matches a summary line passes whatever happens. Match the violation line, as
  `^  <Class>\.<member>  \(<file>:\d+…` does. A plant that makes the gate fail for an unrelated reason (a syntax error
  in the planted class) also passes: each planted class must itself pass every OTHER gate, so check it with the real
  tree's gates on the copy.
- **Gates that read more than src.** `check-dead-methods`, `check-unresolved-sends`, `check-hand-lists` and [U] also
  read the tests repo by a fixed sibling path. A plant in the src copy is still fine; a plant that needs the tests side
  needs that rail too (Unit 0 says which).
- **The shared harvest (Unit C).** `DEF_FORMS` feeds `check-part-edges.js`. A changed harvest can change part-edges'
  verdicts silently in the green direction. Diff its full output before and after.
- **Budget creep.** Measure after each family. Over budget, merge plants into fewer runs before you raise pools.
- **Masks found mid-arc** (expected, §0 reframe 2). Fix a bounded one in its unit, with its own proof. File an
  unbounded one with its measurement; never weaken the proof to get past it.
- **Webkit-only breakage** from a shared runner-lib edit (Playwright `evaluate` takes ONE argument). Covered by the
  webkit check in §5 step 3.

## §7 Rejected alternatives (do not re-attempt)

- **Counting engine fixtures as proof**: see §0 reframe 1 (the settle summary).
- **A hand-kept gate → proof table**, in the index or in a JSON file. It rots silently. Derive it from
  `lib/what-runs.js` (D2).
- **Plants that edit a real holder in place**, in `src/` or in a copy. The plant drifts with the holder's text, and a
  killed run can leave `src/` dirty while a build owns it. Add a throwaway class to a copy (`planted-src.js`).
- **Env-var rails** for a subset, a src root or a prelude. A stray export leaks into gauntlet legs (bite-proofs R6;
  §1.5).
- **One mega self-test for all gates.** A failure names nothing, and the pool cannot run it in parallel.
- **Deleting the catch-all `DEF_FORMS` entry outright.** Measured in §1.4: the class-side and paren-default headers
  plus 14 sent names would false-fail the build.

## §8 Ledger

(Unit 0's per-rule rows, each unit's landing, review findings and their dispositions go here.)

- **Owner decisions 2026-11-07, one round:** D1 (a) the real gate, per rule; **D2 (b)**: the derived file-level
  check PLUS per-rule coverage derived mechanically (every rule token a gate can emit, read from its source, must
  appear in its proof's expectations), so Unit 0 sizes the token reading per gate and Unit E builds it; D3 (a) flags
  only; D4 (a) the callable-only harvest. The §3 constraints (scope = every gate and leg; node tier ≤ 6 s, `selftests`
  leg ≤ wave A's longest) were stated in the round and stand.
- **Gate times, 2026-11-07** (real tree, sequential, load 1.5; `node <gate> >/dev/null`, from `Fizzygum/`):
  run-selftests 1.95 s · syntax 1.40 · shippable-coverage 0.13 · layering 0.41 · invalidation-receivers 0.04 ·
  dead-methods 0.31 · hand-lists 0.20 · unresolved-sends 0.17 · stinks 0.21 · argument-holes 0.80 · menu-actions 0.46
  · thin-wraps, trailing-whitespace, scheduled-checks, stringified-scripts, the three tombstones 0.04 each ·
  part-edges 1.20 · constructors-build 0.04 · call-separation 0.42 · relayout-bounds-first 0.05 · widget-conformance
  `--gate` 0.18 · back-buffer-memos 0.06 · page-loaded-elements 0.07 · relayout-repaints 0.04 · raw-pointer-reads 0.05
  · plane-discipline 0.12 · **tests-syntax 10.72** (so its proof runs on a planted tests dir, never the real one) ·
  macro-source-discipline 0.05 · check-refs 0.10 · check-visualisations 0.11 · aim-census `--tables-only` 0.23 ·
  doc-narration 0.05.
- **The run set's ROOT-launched files (what the meta-rule judges), read from `lib/what-runs.js` `runSet().why`:** the
  build launches the 33 gates of §1.1 plus four BUILD STEPS (`build.py`, `buildProfile.py`,
  `generate-tests-manifests.js`, `generate-pre-compiled-headless.js`); `fg`'s legs launch the §1.2 runners plus
  `run-sequence-headless.js` (the presuite `fracplane` rider). Everything else in the set (143 files) is a library or
  a runner one of those launches. So "a gate" for Unit E = a root-launched file; a build step states so in its header.

### §8.1 Unit 0 — the per-rule survey (2026-11-07; five read-only agents F1, F2a, F2b, F3, F4; raw reports quoted)

**Cross-cutting facts (they reshape Units A, B and E):**
- **C1. No gate but the three bite-proofed ones parses a src rail, and most parse no argument at all.** A `--src=` passed
  today is IGNORED and the real tree checked (measured: thin-wraps, conformance, stinks, doc-narration, macro-source,
  the F1 gates). So a proof written before its rail would pass its control vacuously: every rail lands first, with
  `rejectUnknownArgs` AND a positional refusal. The three existing rails accept an EMPTY `--src=` (→ `path.resolve('')`
  = the cwd = the whole repo): the shared rail helper refuses an empty, missing or non-directory value with exit 2.
- **C2. Repo-relative keys break a naive src rail.** `check-layering` (`USERLAND_FILES`, rel at :514/:728/:878),
  `check-source-vault` (`EXEMPT`, rule 2's `src/boot/` scope, rel at :90) key on `path.relative(REPO, f)`: on a copy
  the control FAILS (`[R] STALE_ALLOWLIST_ENTRY`, three source-vault failures). The rail must keep keys `src/`-rooted:
  `'src/' + path.relative(SRC, f)`. Display-only rels (whole-file-markers, raw-pointer, relayout-repaints (absolute))
  are cosmetic; proofs anchor on the basename.
- **C3. Libraries with their own hard-coded roots** defeat a gate-level rail: `census-public-private-calls.runCensus()`
  (called with NO src by menu-actions :263 and part-edges :443), `lib/install-edges.js` (`SRC`, `BOOT_GLOBALS`),
  `census-call-arity.srcSources()` (argument-holes), `lib/refpaths.js` `TESTS_DIR` (check-refs),
  `build.py --list-shippable` (syntax, coverage, part-edges: part dirs are CWD-relative globs, and include the
  harness `../Fizzygum-tests/...`). Each takes a root parameter in Unit A.
- **C4. The tests repo is always found from `__dirname`**, never from the src root, so a src copy still reaches the
  real harness and tests (good: the member half of part-edges, menu RULE 1b, dead-methods' references, layering [D]'s
  tests half stay live). A plant that needs the TESTS side needs a tests rail (layering [D] whole-file mode;
  aim-census UNKNOWN VERB) — those are stated per rule below.
- **C5 (X1). `what-runs.js` cannot see a G proof launch its gate.** Every E self-test `require`s its gate (counted as a
  launch); every G proof passes the gate's name through a variable (`runGate(GATE)` → `path.join(BUILD_SYSTEM, script)`)
  and is seen launching nothing. Unit E needs a proof-launch reader (D2) that understands the proof helpers' call, or
  the proofs spell `path.join(__dirname, '<gate>.js')`.
- **C6 (X2, X5). Where a proof may live and what it may hold.** A `buildSystem/` proof must not hold a name-list-shaped
  literal (check-hand-lists scans buildSystem `.js` string literals; `["Widget", "PanelWdgt"]` in a plant text
  fails the build); a dead-methods plant must not live in `Fizzygum-tests/scripts/` (read as references); a
  run-selftests fixture is generated in tmp at run time (a committed `x.selftest.js`, or a bare `'--selftest'` literal,
  fails the build).
- **C7. Format coupling to keep:** `fg:65` greps `selftests\] (OK|FAIL)|dead-methods\]|unresolved-sends\]|stinks\]
  (OK|FAIL)|aim-census\] (OK|FAIL)`; `fg:891-893` grep `UNDER|NOTE|OK --` / `NOTE|OK —`. Pass output stays
  byte-identical (Unit A exit).
- **C8. D2(b) sizing.** Only check-layering (`[A]`…`[T]` heads in `violations.push` templates), run-selftests
  (`SELFTEST_*`), hand-lists (`token: '…'`), unresolved-sends (`BUILTINS_*`), menusweep/pinsweep (`kind: '…'`),
  gate-tokens (`GATE_TOKENS`), stinks (`id:`), doc-narration (`RULES` labels) carry a readable token. The other ~25
  gates print ad-hoc text (`FAIL --` headers, `UNSHIPPED`, a bare `FAIL <path>`), and a generic UPPER_SNAKE reader is
  noise (table names `PLATFORM_GLOBALS`, `METHOD_HEADER`, `PENCIL_TOOL_SOURCE`, 18 aim-census table constants).
  Mechanical per-rule coverage therefore needs ONE emitted convention: design in §8.2.
- **C9. D3 is wider than §1.5 measured.** Beyond `PRELUDE_JS` (8 readers: the five rigs via `prelude-from-env.js`,
  run-all-headless (refused without `--tests`), run-macro-test-headless and run-sequence-headless (unconditional)) and
  `AIM_CENSUS_SRC`: `AUDIT_PRELUDE` is honoured by run-all-headless on the WHOLE suite and is already used as a plant
  rail by `derive-inspector-churn-set.js:245` and `run-atlas-fuzz.js:365`; `FUZZ_ATLAS`/`FUZZ_SEED`/`FUZZ_MAX_MS`
  (`lib/atlas-fuzz.js`) inject into both serialization rigs; `AUDIT_CHROME_ARGS` silently changes Chrome flags on
  dpr1/dpr2. A stray export of any of them arms a gauntlet leg silently. ~40 files mention the family.
  `what-runs.js:110` reads a `PRELUDE_JS="${3:-x.js}" node …` assignment as a LAUNCH (audit-one.sh): moving it to a
  flag needs what-runs to read `--prelude=<x.js>` as one.
- **C10. Budget.** Node tier: F1 ≈ 17 runs × 40 ms; F2a ≈ 2 s CPU (syntax via `--files` 0.15 s, full copy 3 s);
  F2b ≈ 6 s CPU (part-edges 2.5 s, menu-actions 1.4–1.9 s, both dominated by `runCensus` 0.42 s/run); F3 ≈ 6 s CPU. ≈ 14 s
  CPU pooled 4-wide ≈ 3.5–4 s wall + today's 1.95 s → AT the 6 s budget: merge plants into one run per gate, mini
  trees where the gate's input allows (argument-holes, syntax), and measure after each family. Headless tier: the
  last gauntlet's 8 files = 389.6 lane-s → 145.5 s wall (pool 3); F4 estimates +≈700 lane-s for the new leg proofs ⇒
  ≈ 370–400 s at pool 3, over the ≈ 211 s budget. Levers: the refs leg's three proofs need no browser (node tier);
  apps, paint, serialization, vmtruth need subset rails (one app / one test / one section); then `HEADLESS_POOL` is
  re-measured (§3: "raise HEADLESS_POOL or split the leg, with a measurement either way").

**Per-gate rows.** Proof kind before → after; rail; each RULE with its plant (⟂ = the control/sanctioned forms that
must pass); unplantables with the reason; masks found (disposition in §8.3). Plants are throwaway `BiteProof*` files in
the copy unless stated; "edit" = an in-copy edit of a real holder, allowed ONLY where no addition can reach the rule,
anchored on a regex whose match the proof asserts (so drift fails loudly, §7's rejection is about plants that
silently drift).

- **#1 run-selftests** (1.95 s; E → G; rail: `--umbrella=DIR` threading a layout through `discover`, `scriptFiles`,
  `repoFiles`, `repoOf`/`rootOf`, `testsPresent`, `UMBRELLA`; mini workspace generated in tmp). SELFTEST_FAILED (a
  self-test printing a FAIL verdict) · SELFTEST_NO_VERDICT (prints nothing) · SELFTEST_VACUOUS (`— 0 cases`) ·
  SELFTEST_OUTSIDE_CONVENTION (a script string literal offering the switch; the literal assembled at run time, C6) ·
  SELFTEST_UNDISCOVERED (`m.selftest.js`) ⟂ a passing self-test, a comment/echo naming the switch, the names under
  `tests/`, `node_modules/`, a dot-dir. `--headless` tier: a verdict-only headless fixture. Unplantable: "run ended
  before verdict" (defensive: `runAll` awaits every close). Operational exit 2 (none found, unknown arg) proven as
  cases, not rules. ~1 s.
- **#2 syntax** (1.40 s; N → G; rail: `--src=DIR` consumed by the gate and handed to `build.py --list-shippable
  --src=DIR`, which rebases the `src*` part dirs; `--files` stays). PARSE (class: a `if (` body; mixin variant) ·
  LOST_HELPER (`a %% b` → `modulo`; `(c = @color ? @fallback()) ->` → `ref`) ⟂ provided helpers (`in`, `a[1..]`,
  `for own`), `@field` before `super`, bare `super`, a mixin using `%%` (mixins are not checked). Masks: class parse
  errors report the FRAGMENT's line (`(2:9)` for file line 7); a non-class non-mixin file is skipped silently under
  `--files`; no `rejectUnknownArgs`; vestigial `nil` shim in the header.
- **#3 shippable-coverage** (0.13 s; N → G; rail: `--src=` + build.py's). UNSHIPPED (`biteproof-unclaimed/X.coffee`;
  a nested `basic-widgets/biteproof-nested/X.coffee`, since globs are non-recursive) · STALE_ALLOWLIST_ENTRY
  `ALLOWLIST_PREFIXES 'src/boot/'` (delete the copy's `boot/`, its own run) ⟂ a file at the copy root, a file under
  `boot/`. Masks: stale fix advice (~lines 191-233 of build.py, `--includeVideoPlayer`), same stale text in
  build_it_please.sh.
- **#4 layering** (0.41 s; N → G; rail: `--src=` at :55, rel rebased (C2); `--tests-dir=` for [D]'s whole-file
  half). 31 violation templates (`violations.push` / `warnings.push`), plants verified isolated by the F2a agent,
  all in ONE run as ~19 files: A-public-setter · A-text-setter · A-recalc (co-fires [B] on the same line by
  construction: expected pair) · B ⟂ `doOneCycle` · C (`super` is load-bearing: settling-setters throws on a
  non-settling non-super override) · D (append a `Macro.fromString """…"""` member to the copy's
  `macros/MacroToolkit.coffee`: a private call, a `raw[A-Z]` call, a marker with no reason) ⟂ same-line and line-above
  `# macro-private-call-sanctioned: …` · E-invalidate · E-valve ⟂ the hard-coded `Widget._applyExtent` site · F ⟂
  `# layout-apply-sanctioned:` above, guards · G-wrapper (with the "ALSO a plain" suffix) · G-@add ⟂
  `# nosettle-sanctioned:` above · H (a WARNING, exit unaffected; the real tree carries one: anchor on the method) ⟂
  `# early-return-sanctioned:` · I · J ⟂ a quiet hook · K-seam · K-dispatch · K-commit ⟂ a reacting twin · L-NoSettle ·
  L-malformed · L-legacy · M-fragment · M-suffix · N · O ⟂ `nonFloatDragging` · P ⟂ a `_…Connector` · Q ⟂
  `recalculateOutput` · R (append to the copy's `basic-widgets/menu-system/MenusHelper.coffee`, the one USERLAND file)
  ⟂ `# private-use-sanctioned:`, `this._x()`, `@_x()` · T (four labels) ⟂ `# double-settle-sanctioned:` · stale
  tables, a SECOND planted run of edits: G-stale `WRAPPER_EXCLUDED` (rename the copy's settling `add:` headers),
  O-stale / Q-stale (rename the deferred-settle / connector calls in their callers), R-stale (unplant
  MenusHelper; THIRD run). Masks: ONE-LINE METHODS ARE NEVER CHECKED (279 one-liners; checkFile, checkDoubleSettle and
  discoverSettlingWrappers skip the header line), [D]'s pending sanction leaks across heredocs and blank lines, [D]'s
  src half is skipped when the tests repo is absent, the [E] valve exemption has no stale check, the index says markers
  work "anywhere in the body" (they exempt only lines at or below them), the index's [O] row names `*Coalesced` (the
  code: `*DeferredSettle`), the PASS line omits T, no argv handling. ~1.1 s.
- **#5 invalidation-receivers** (0.04 s; N → G; rail `--src=`). CROSS_INVALIDATION (`other._changed()`,
  `other.fullChanged()` (legacy spelling), `world._repaintDamagedRects()`, a marker with no reason) ⟂ same-line and
  line-above `# cross-invalidation-sanctioned: …`, `@_changed()` · STALE executor (rename the copy's
  `_repaintDamagedRects:` header; own run). Masks: `this._changed()` flagged as cross-object; `#` inside a string cuts
  the line; STALE exits 1 not 2; no argv handling; build_it_please.sh comment says the singletons are allowed.
- **#6 dead-methods** (0.31 s; E → G; rail `--src=`; tests root stays real). UNSEEN_HEADER (a wrapped
  `biteProofWrapped: (a,` header; exits BEFORE every other rule → own run) ⟂ `foo: (` at end of line · DEAD (`biteProofNeverReached: -> 1`)
  ⟂ reached by a whole-name string, a name template, a computed class access, `{m} = x` · DEAD pair (both twins dead)
  ⟂ the symmetry exemption (a live `_xNoSettle`): NOTE only · STALE_ALLOWLIST_ENTRY no-longer-dead (a planted
  `@x.getBody()`; the entry name read from the real allowlist at run time) · STALE no-method (unplant
  `fizzytiles/LCLProgramRunner.coffee`; own run) · STALE redundant-by-symmetry (`_asArrayNoSettle` + a caller).
  Unplantable: the SKIP (tests absent) without a tests-root rail. ~1.0–1.3 s.
- **#7 hand-lists** (0.20 s; E → G; rail `--src=` for the tree ratchet; `--files`/`--fg=` exist). OVER_BASELINE
  (tree mode, no token today: a planted `@things: ["Widget", "PanelWdgt"]`) · UNSANCTIONED_NAME_LIST (`--files`) ⟂ a
  data list, a lone name, a list in a comment · SANCTION_NAMES_NO_GUARD · SANCTION_EMPTY · SANCTION_STALE ⟂ a marker
  on the opening line, a DECLARATION key, a quoted marker · SANCTION_GUARD_NEVER_RUNS (a token a given file emits and
  no running file does) · SANCTION_UNVERIFIED is a NOTE (with `--fg=/nonexistent`), not a rule. The plant TEXT lives in
  a fixture written at run time (C6). Masks: in `--files` mode any given `.coffee` counts as a running world source
  (a plant can vouch for its own sanction); the count ratchet cannot see a swap. ~1 s.
- **#8 unresolved-sends** (0.17 s; E → G after Unit C; rail `--src=` + `label()` rebased). UNRESOLVED (no token today)
  ⟂ `# @x()`, `"@x()"`, `x.Cap()`, an allowlisted vendor call, a bare and a keyed BUILTIN · STALE_ALLOWLIST_ENTRY
  allowlist (plant `digest: -> 1`) · STALE BUILTINS (unplant `icons/CurledArrowsSquareIconAppearance.coffee`, sole
  sender of `asin`; own run) · BUILTINS_NOT_KEYED (plant `isView: -> 1`) · BUILTINS_KEYED_NOTHING_TO_UNMASK (deletion
  of the sole definer; after Unit C `Array.from` goes bare, so re-pick) · PLATFORM_GLOBALS_NAMES_FIZZYGUM (a
  `performance.coffee` class) · STALE PLATFORM_GLOBALS (deletion; `window`'s only send is in the harness → needs a
  harness rail, else re-pick). Unplantable: BUILTINS_KEYED_OFF_PLATFORM (both sides are in-file constants). Masks:
  form 6 (§1.4, re-measured below), the FORM-5 mask (7 names, 709 sites: `width`, `left`, `right`, `extent`, `add`,
  `corner`, `resolve` resolve through a local `width = …` in an icon appearance), §1.4(iv) is mis-stated (5 of the 6
  platform names are already bare BUILTINS; `from` is `Array.from`, keyed).
- **#9 stinks** (0.21 s; N → G; rail `--src=` + `rejectUnknownArgs`; no exports). One plant file at the copy root with
  `baseline − current + 1` lines per stink, read from the control run's own `[stinks] <id>: N site(s) (baseline B)`
  lines; each plant line verified to hit exactly one stink: debugger-statement · nil-literal · null-literal ·
  wall-clock · timer · math-random · instanceof-type-test (UNDER today, 74/75 → 2 lines) · positional-hole ·
  raw-chrome-color · comment-meta-edit · comment-narration · commented-out-debug · comment-past-receipt ⟂ a colour
  literal in an excluded prefix, the 35 sanctioned hits · STALE SANCTION (unplant `ColorPickerWdgt.coffee`; own
  run) · STALE_ALLOWLIST_ENTRY exclude (remove `examples-icons/`; same deletion run) · SANCTION COUNT (an in-copy edit
  anchored on the sanction's own `^  <member>\s*:` header: the one form that reaches it). Masks: `comment-meta-edit`'s
  `to be clear,` alternative cannot match prose (trailing `\b` after a comma); `instanceof-type-test` sits UNDER (one
  new `instanceof` passes today: tighten 75 → 74).
- **#10 argument-holes** (0.80 s; N → G; rail: a src parameter for `census.srcSources`). OVER_BASELINE (a hole on its
  own line; assert `FAIL — (control count + 1)`; mini tree of BASELINE holes for the control, +1 planted: 0.1 s) ⟂ a
  trailing `undefined`, `fn.call undefined, 1`, a commented call, a multi-line call ending in `undefined`. Masks:
  strings read as code (`@say "use undefined, then 1"` is a hole); UNDER exits 0.
- **#11 menu-actions** (0.46 s; N → G; rail `--src=` threaded to `runCensus({src})` and install-edges, else RULE 1b
  skips the plant silently at :304). RULE_1 menu door (function literal action) · RULE_1 prompt door (function literal
  callback) · RULE_1B (`@`-row and `@`-prompt naming nothing) ⟂ a verb defined only by a subclass, a mixin
  consumer's verb, an installed harness member (`popUpSystemTestsMenu` on a WorldWdgt subclass) · RULE_2 (a string
  `opts`) ⟂ `{toolTip: "x"}` · RULE_3 unread parameter (own run: a hard violation exits before the ratchet) ⟂
  `ignored`/`unused3` names, a read parameter. install-edges refusals are exit 2 (owned by part-edges' proof).
  Masks: RULE 3 never reads a wrapped signature and reads a one-liner's inline body as unread; RULE 2 skips an opts
  string containing `:`; RULE 1's regex flags any action starting with `(` (false-positive risk); the UNDER branch is
  dead at baseline 0; the index's "136 rows" is stale (122). ~1.4–1.9 s.
- **#12 thin-wraps** (0.04 s; N → G; rail `--src=`). NOT_CANONICAL ⟂ `# thin-wrap-exempt:` above (exempt +1), a guarded
  canonical body, a private twin pair, a twinless `_xNoSettle` (count-line deltas). Mask: NO STALE-EXEMPTION CHECK — 9
  of the 18 `# thin-wrap-exempt:` markers sit above methods with no twin and excuse nothing (WorldWdgt:3200,
  DivisionStackLayoutSpec:96/101/105/109, VerticalStackLayoutSpec:116/122/126, CaretWdgt:327). Comment drift in
  build_it_please.sh and the footer.
- **#13 trailing-whitespace** (0.04 s; N → G; rail `--src=`). TRAILING_WHITESPACE (a space and a tab) ⟂ a
  whitespace-only line. Mask: CRLF lines hide it (`$` without `m`; two CRLF files in src/boot, clean today); U+00A0
  unmatched.
- **#14 scheduled-checks** (0.04 s; N → G; rail `--src=`; verdict depends on `Date.now()`, so ISO dates far from now).
  OVERDUE (`# CHECK AFTER 2000-01-01T00:00:00Z`) ⟂ `2999-01-01T00:00:00Z` · UNPARSEABLE (`not-a-date`). Masks: a dateless
  or hyphenated marker is not a marker; text after the date makes it unparseable.
- **#15 stringified-scripts** (0.04 s; N → G; rail `--src=`). STRINGIFIED_SCRIPT ⟂ above-block and on-line
  `# stringified-script-sanctioned: …` (assert `scan done (2 sanctioned)`); must still FAIL: an empty reason, a sanction
  separated by a blank line. Masks: escapes `new ScriptWdgt("""`, `'''`, a one-line string, a next-line `"""`.
- **#16 region-markers** (0.04 s; N → G; rail `--src=`). REGION_HOMEPAGE · REGION_MACROS · REGION_VIDEOPLAYER (all
  three SUMMARY-ONLY today: no line names the file → the gate gains a per-hit line) · UNPAIRED · UNKNOWN_MARKER ⟂ the
  PROSE form (3 real sites). Dead: the "tighten" branch at baseline 0.
- **#17 source-vault** (0.04 s; N → G; rail `--src=` with rel rebased (C2)). COFFESOURCE_GLOBAL · BOOT_WINDOW_KEY_SCAN
  (`boot/BiteProofBootScan.coffee`) ⟂ the scan outside `src/boot/` · STALE no-such-file (unplant
  `boot/source-vault.coffee`) · STALE excuses-nothing (replace it with a hit-less class; own run). Masks: the scan misses
  paren-less `Object.keys window` and `Object.getOwnPropertyNames window` (boot uses the latter in `allClassFunctions`);
  the header's two "outside the boot layer" scans no longer exist; the exempt file is excused wholesale.
- **#18 whole-file-markers** (0.04 s; N → G; rail `--src=`). MARKER_HOMEPAGE · MARKER_MACROS · MARKER_VIDEO_PLAYER ⟂ a
  prose line quoting a marker. No existsSync on the walk (a missing root throws, exit 1).
- **#19 part-edges** (1.20 s; E → G; rail: `--src=` + `--parts=FILE` honoured by part-edges AND
  `build.py --list-shippable`, plus `runCensus({src})` and install-edges threaded). CLASS_REF (lazy
  `SimpleUSAMapIconAppearance`, eager `HhmmssLabelWdgt`) · INHERIT (a LAZY base, so its line differs from an eager
  ref's) · MEMBER_A (`@serialiseToMemory()`) · MEMBER_B (`"deserialiseFromMemoryAndAttachToWorld"`) · MEMBER_C (a
  `super` in `fullRenderCanvasAsItAppearsOnScreen`) — three DIFFERENT members (a definition outside the harness
  removes a name from `soleProviders`) · UNUSED_REQUIRES (planted parts.json: `maps.requires += "plots"`) ⟂ the name
  in a comment/string, `X?`, `if X?` block + continuation, `return unless X?`, a guard on a same-part class,
  `whenAllLoaded`, `requiredParts`, a covering `requires`, the member guards, `super.other()`; must still FAIL:
  `whenOptionalPartsLoaded`, an eager part requiring a lazy one. Operational (exit 2): parts.json with only core; a
  requires cycle. Masks: no vacuity floor on the member half; inherit and eager-ref lines are indistinguishable; no
  positional refusal. ~2.5 s (the longest node proof).
- **#20 constructors-build** (0.04 s; N → G; rail `--src=`). CTOR_BUILDS_CHILDREN ⟂ the exempt marker above and in the
  body (exempt +1), `@contents._addNoSettle x`, `@_buildAndConnectChildren()`. Masks: a one-liner constructor is
  invisible; build_it_please.sh comment names `@_buildScrollFrame()`/ScrollPanelWdgt.
- **#21 call-separation** (G, kept; rail exists). Its proof moves onto the shared helper (§8.2).
- **#22 relayout-bounds-first** (0.05 s; N → G; rail `--src=`). RELAYOUT_READS_BEFORE_APPLY ⟂ `_applyGrantedBounds`
  first, `_applyBounds`, move+extent, `super` first, the exempt marker, no geometry read · HOOK_WITHOUT_TEMPLATE ⟂ a
  delegating class and its hook-only subclass. Masks: a read before the delegate line passes; `\bsuper\b` matches a
  string; hook violations ignore the marker the footer offers; the index's "blind to a file defining the hook and NO
  `_reLayout`" is wrong (the code resolves it).
- **#23 widget-conformance `--gate`** (0.18 s; N → G; rail `--src=` + `rejectUnknownArgs`). UNDECLARED_FIELD ⟂ a
  class-level declaration, a mixin donation, a write in a block string, `@x == 1`, `@x =>`; NB `constructor:
  (@bpY) ->` counts as a write · PROLOGUE_COPY (9 > 8; anchor `\)$` so a facet-1 row cannot match). Mask: `?=`, `+=`,
  `or=` writes are invisible (the lazily-initialised fields are the target).
- **#24 back-buffer-memos, #25 page-loaded-elements** (G, kept; rails exist; empty `--src=` refused in Unit A). Their
  proofs move onto the shared helper.
- **#26 relayout-repaints** (0.04 s; N → G; rail `--src=` (ROOTS[0]); the harness root stays real). RETIRED_VERB (both
  spellings) ⟂ the real harness. Masks: `\b` misses `_disableTrackChanges`, `…NoSettle`; a missing harness is skipped
  silently.
- **#27 raw-pointer-reads** (0.04 s; N → G; rail `--src=`). RAW_READ (a `pressBegan` and a `takeStrokeScrollFrom`
  body) ⟂ same-line `screenPointToMyPlane`, the marker above, a read in a helper or comment; must still FAIL: the marker
  in the previous method's body · TABLE_UNKNOWN_NAME (edit: drop every `scrolledBy` from the copy's ActivePointerWdgt) ·
  TABLE_UNLISTED_DISPATCH (additive: a probe member) · TABLE_POS_MISMATCH (additive) · TABLE_STALE_POSITION_QUERY
  (edit) · TABLE_UNMAPPED_PLANE_HANDLER (edit) — the table check exits before the body scan, so the table plants are
  their own run · STALE `EXTRA_HANDLER_NAMES` (edit: rename `takeStrokeScrollFrom:`). Unplantable: STALE
  `SKIPPED_CLASSES` (dead: removing ActivePointerWdgt trips "not found" first). Masks: a column-0 line inside a handler
  ends it; any `screenPointToMyPlane` on the line excuses the read.
- **#28 plane-discipline** (0.12 s; N → G; rail `--src=`; no single PASS line: all three `-- OK` lines). A_BARE_WRITE ⟂
  inside `_writeScrollOffset`, a class-level `scrollOffsetX: 0`, `==` · B_ROSE (one mixing line; 32 > 31) ⟂ `@`-rooted,
  `@bounds`-folded, mapped · B_DROPPED (edit: blank one real B line taken from the planted run's own output; own run) ·
  B_STALE_NOT_POSITIONAL (edit: give `hasMaybeChangedPaintBounds` a parameter) · C1_ESCALATED_POS (a provider whose
  `activated` reads `pos`; a subclass too) ⟂ the marker, `(ignored)`, no parameter, a body that only escalates, a
  non-provider · C2_RAW_SCREEN_POS ⟂ mapped on the line, `ignored…`, the marker · operational exit 2 (no Widget.coffee;
  a vacuous derivation). Unplantable: STALE `NON_WIDGET_ROOTS` (the table is empty; dead branch). Masks: `+=`/`?=`/
  destructuring writes escape A; A's sanction is by NAME; C reads only a one-line header; the "escalated" marker also
  exempts C2 (index says C1 only).
- **#29 tests-syntax** (10.72 s; N → G; rail `--tests-dir=` refusing a missing dir). SYNTAX_ERROR (a stray backtick in a
  macro comment; a broken metadata file) ⟂ valid pairs (assert the exact N), out-of-scope files (a top-level manifest,
  `automation-assets/**/*.js`, a non-`SystemTest_` dir, a non-prefixed `.js`). Masks: exit 2 documented, not
  implemented; ENOENT `node` counted as a syntax failure; header's "~320 files, ~1s" (746 files, 10.7 s); argv ignored;
  `node` from PATH not `process.execPath`.
- **#30 macro-source-discipline** (0.05 s; E → G; rail `--tests-dir=`). TOOLKIT_EVAL · MIDNAME_MACRO · UNDECLARED_EVAL
  (kinds exist in code but are never printed) ⟂ a test tagged `evaluateString`, a comment naming both, a lookalike
  identifier, `…_Macro` as a suffix. Masks: no exit-2 path; zero tests passes vacuously; every backtick in the file is
  paired (the macro span is found today only because each header comment holds an even number of backticks).
- **#31 check-refs structural** (0.10 s; N → G; rail `--tests-dir=` through `refpaths`; the harness-version path
  stays real). DUPLICATE · ORPHAN · STALE_AUTOMATOR_VERSION ⟂ a `finger/` sibling, two versions in one group, a
  non-SWCanvas path, a non-grammar name, a matching pair. Unplantable without a harness rail: CANNOT READ. Masks: zero
  refs passes; the PASS line is suppressed under `--quiet`.
- **#32 check-visualisations** (G for the build mode; `--strict` NOT covered: refused with `--tests-dir`, and
  `renderVisualisation` reads the module-level `TESTS`). STRICT_STALE_PAGE needs `--strict` + `--tests-dir=` (thread
  `TESTS` through `make-visualisation.js`). Mask: its existing cases check exit codes only; `--strict` passes when
  the render is undefined.
- **#33 aim-census `--tables-only`** (0.23 s; N → G; rail `--src=` parsed BEFORE the module-load derivation,
  `AIM_CENSUS_SRC` retired; `--tests-dir=` for the test side). UNCLASSIFIED_VERB src side (`biteProofAim_InputEvents`)
  ⟂ a private `_bp_InputEvents` · STALE_NAME (unplant one `TEXT_CLASS_ROOTS` root; own run) · UNKNOWN_VERB /
  UNCLASSIFIED_VERB test side (tests-dir plant) · EMPTY_DERIVATION (`--src=<empty dir>`, exit 2: operational).
  Unplantable: STALE ARGUMENT, CLASSIFIED TWICE (in-file tables), UNSETTLED DERIVATION (a 24-deep chain).
- **doc-narration** (refs leg; 0.05 s; N → G; rail `--docs=DIR`, refusing `--write-baseline` beside it). One rule per
  `RULES` label (11; one plant line each, verified to hit only its own label; `--full` names the label) ⟂ STAMP words,
  `<!-- narration-ok:`, fenced and inline code, an unscanned bucket. Masks: a missing bucket/docs root passes
  (`OK — 0 docs`); the backtick branch of the-then/old- rule is dead; no exit-2 path.
- **Suite legs dpr1/dpr2/webkit/finger** (`run-all-headless.js`; E pieces → G end-to-end; rails `--tests=` exists,
  `--prelude=` replaces PRELUDE_JS). SCREENSHOT_MISMATCH (wrap `AutomatorPlayer.prototype.compareScreenshots`, shift one
  pixel on T) · MACRO_INCOMPLETE · AMBIGUOUS_REFERENCES · each GATE token of `lib/gate-tokens.js` (one plant emitting
  every token ≥ 1.5 s into T: attribution lags the 1 s poll) ⟂ `DATAFLOW_ERROR` (NOT_GATED) · UNTOKENIZED_CONSOLE_ERROR ·
  UNCAUGHT_PAGE_ERROR · STALLED (no-op `doOneCycle` on T; +35 s, optional). Chrome AND WebKit. Unplantable from a page:
  CRASHED, ERRORED (and boot-fail costs 2×90 s). Masks: `suiteResultPasses` never checks Σ shard totals = probed
  total; an infinite JS loop escapes the per-test watchdog (10 min protocol timeout). ~60–100 s.
- **apps** (`smoke-apps-headless.js`, 106 s; N → G; rails needed: `--apps=X` subset, `--prelude=`). LAUNCH_THREW ·
  ERROR_DURING_LAUNCH · DISCOVERY_EMPTY (exit 2). Unplantable confined: world-not-ready; no-icon (same lookup).
  Masks: no error listeners on the discovery page; launch pages' boot errors excluded; no floor on the app count.
- **parts** (3 rigs, 74 s; N → G; `--prelude=` rail on each). lazy-load (19 checks), snapshot-load (15), lazy-icons
  (22, incl. `STALE_ALLOWLIST_ENTRY SAMPLE` and `ISOLATION_CHECK_VACUOUS`): one rule = the `[FAIL] <check>` kind per
  rig, plus the two tokens; plants in the F4 report §3. Masks: snapshot-load drops page b's errors; `[SKIP] window.gc
  unavailable` passes; IIFEs without `.catch`.
- **menusweep** (26 s; N → G; `--prelude=`). 22 kinds (`/kind: '([A-Z_]+)'/` ∪ `[FAIL] X`), host = a leaf
  representative's own `addWidgetSpecificMenuEntries` guarded on its constructor: THREW, UNRESOLVED_ACTION,
  NON_STRING_ACTION, NO_TARGET, SUBMENU_FLAG_MISMATCH (both directions), ELLIPSIS_MISMATCH (both), ASCII_ELLIPSIS,
  SENTENCE_CASE, PROMPT_CALLBACK_ARITY, PROMPT_OK_MISSING, PROMPT_OK_NOT_WIRED, PROMPT_OK_THREW,
  MENU_CONTRIBUTOR_UNSWEPT, STALE_ALLOWLIST_ENTRY for KNOWN/CONDITIONAL_OPENERS/ELLIPSIS_EXCEPTIONS, ROOT_UNBUILT (own
  run), POPOUT_BUTTON_UNSWEPT, BUTTON_FACE_MISSING, the five `*_VACUOUS` (one drastic run). Unplantable: stale entries
  of the EMPTY tables SKIP, SKIP_PROMPT, SENTENCE_CASE_EXCEPTIONS. Mask: console/page errors are printed, never fail.
- **pinsweep** (26 s; N → G; `--prelude=`). 10 kinds (NO_SETTER, NO_GETTER, PINS_THREW, POPULATION_SHAPE_THREW,
  APPEARANCE_PIN_WITHOUT_WEARER, NO_SETTER_FOR_APPEARANCE_PIN, ANNOUNCES_WITHOUT_FIXTURE, ANNOUNCES_FIXTURE_THREW,
  ANNOUNCES_BUT_SETTER_IS_SILENT, STALE_ALLOWLIST_ENTRY) + CONSOLE_ERROR (own run: reached only at zero violations).
  Masks: no floor on classes/pins checked; no `.catch`.
- **graph** (26 s; N → G; `--prelude=` rail needed). One rule per section's FAIL kind + STORAGE_INVARIANT + CONSOLE_ERROR;
  plants cascade, so match each section's label. Mask: no `.catch`.
- **selftests** (the runner; its proof is #1's, node tier).
- **paint** (`run-paint-audit.js`, 182 s whole-suite; N → G; rails needed: `--tests=`, `--prelude=`). OFFENDER (write a
  stale pixel at T's stop) · COVERAGE_HOLE (sharded: skip T's audit) · AUDIT_FLAG_OFF (exit 2). Masks: page errors and
  failed tests never fail; the `--shards=1` path skips checked==expected (0 checked passes); `auditWasOn` reads the flag
  the script itself set (the exit-2 branch is vacuous).
- **tiernaming / settle / capstone / revisits / storage** (G, kept): uncovered rules — tier-naming
  `TIERNAMING-UNCLASSIFIED`/`-STALE` (plantable), `arrange-fired-seam` (DEAD: the seam is gone), embedded-suite FAIL ·
  capstone unclassified record (plantable: a foreign `LAYOUTAUDIT` tag), the backfill path (`audit-one.sh:16`
  overrides PRELUDE_JS, dropping a plant) · storage: 8 of 9 prelude finding kinds · revisits: VANISHED direction
  (unplantable with an empty baseline). The shared install-gap / embedded-suite / exit-3 paths are operational.
- **refs** (node tier, ~1 s; see #31, #32, doc-narration) plus `--pixels`: PIXEL_HASH_MISMATCH (an altered base64 PNG)
  · DECODE_FAILED · NO_SWCANVAS_REFS (`recompress … --check-only` on a temp tree). Masks: a pixel mismatch prints WARN
  (the `consistency FAILED : N` total fails); under `--quiet` the SKIP lines the failure points at are suppressed.
- **census** (23 s; N → G; `--prelude=`). MOVER (non-idempotent `_reLayout` on a battery class) · BATTERY_SKIP · ERRORS
  (a page error) · STORAGE_FINDING; detail lives only in the JSON dump. Unplantable: stale KNOWN_MOVERS /
  NOT_BATTERIED (empty tables). Mask: NO CONSOLE LISTENER (a console.error token passes); a missing bin opener is
  skipped silently.
- **serialization** (185 s; partial → G; rails needed: `--prelude=` on both rigs, a section/subset rail). MISMATCH (a
  serializer that drops a `color` field) · UNREPORTED_EXPECTATION (needs a Node-side rail) · file-rig `[FAIL]` (a
  `FileSaving.saveStringAsFile` that alters the bytes). Unplantable from a page: STALE `SWCANVAS_ONLY_CHECKS`, the
  SW-only-unnamed rule. Masks: boot/page errors only add a note; console.error collected only with `--verbose`; 21
  emitted names are missing from `EXPECTATIONS` (`spreadsheet.roundtrip.*` ×10, `arrowContract.*` ×4, …), so the
  unreported self-check cannot see them vanish.
- **vmtruth** (128 s whole-suite; N → G; rails: `--out=` replacing the FIXED `.scratch/vm-truth-gate-out` (an R2
  hazard), `--prelude=` through). RETAINED (a destroyed boot-world widget kept by a closure; T's opening reset sweeps
  it) · UNKNOWN_VMTRUTH_TOKEN (rides along) · INVALID unobserved bucket (the shared blind plant) · INVALID UNCONFIRMED
  (a primitive pushed into the suspect array). Unplantable on a short run: the heap-floor ceiling (≥ 20 samples per
  page). Masks: a capped suspect list is a WARNING; the heap floor is skipped below 20 samples; a runner refusal reads
  as INVALID.
- **run-sequence** (presuite `fracplane` rider; not a gauntlet leg). Mask: the completion wait's result is ignored, so
  an unfinished sequence can exit 0. A proof is in scope only if Unit E's run set counts presuite legs (it does: fg's
  `fg_suite`/`run_leg` bodies are roots) → one plant (a pixel shift) on one of its two tests.

**Appendix A re-run (2026-11-07):** identical (`files 586, masked 62, maskedSites 2388, withReal 48, withRealSites 2337,
onlyData 14, onlyDataSites 51`). With the gate's own excuses (BUILTINS, allowlist, macro sites; 10322 calls), dropping
form 6 and adding a header form with the arrow ANYWHERE on the line leaves **3 sites / 3 names** to rule on:
`overridingContextMenu`, `addCheckMarksAndUpdateCodeAndNotifyChange` (backslash header), `drawFunction`. And 85 MACRO
sites over 6 paren-default MacroToolkit verbs resolve only through form 6 today (Appendix A does not count macro
sites): the paren-counted header form must catch them. `Array.from` must go BARE (its only Fizzygum "definition" is
the local `from = start` in `CanvasWdgt.coffee:163`, form 6). Form 5 masks 7 names / 709 sites (above); 2 names
resolve ONLY through form 5 (`push`, a BUILTIN anyway; `swCanvasAnyTextDirty`, a real top-level boot global).

### §8.2 Owner round 2 (2026-11-07, after Unit 0) and the design it fixes

- **D2(b) shape: a rule REGISTRY** (owner chose it over a per-gate token regex and over falling back to D2(a)).
  `Fizzygum/buildSystem/lib/gate-rules.js`, one per gate process:
  - `rules.fired('<ID>', text)` records the rule and returns `text` unchanged (passing output stays byte-identical);
    the ids a gate can fire are read from its OWN source (literal first arguments of `.fired(`, code only, via
    `lib/js-mask.js`), plus `rules.declare(ids)` for a table-driven gate (stinks ids, tombstone kinds, `GATE_TOKENS`,
    narration labels, menusweep/pinsweep kinds). An id fired but never declared is a gate bug: exit 2.
  - `rules.exit(code)` is the gate's only exit. An exit 1 with no fired rule is `RULELESS_FAILURE` (exit 2): a new
    failure branch cannot hide outside the registry. On exit 1 it prints one machine line,
    `[<gate>] RULES fired: A B · of: A B C · unplantable: D`.
  - A rule no plant can reach is stated in the gate's header: `// bite-unplantable: <ID> — <reason>` (read by the same
    source reader; an id listed there that the gate cannot fire is stale: exit 2).
  - The shell gates get the twin in `lib/audited-suite-with-infra-retry.sh`: `gate_rule <ID>` and `gate_exit <code>`,
    ids read from the script's own `gate_rule <ID>` words.
  - **The proof helper** (one per kind: `planted-src.js` for static gates, `gate-bite-proof.js` for browser rigs)
    takes a spec of planted runs, each `{ plants, expect: { <ID>: /own violation line naming the plant/ } }` plus the
    control and the sanctioned forms. It requires, mechanically: each expected id is in that run's `RULES fired`; each
    regex matches a line of that run; the union of fired ids over the planted runs equals `of`; every planted run exits
    1; the control exits 0 with its pass line. So a gate that grows a rule fails its proof until the proof plants it,
    and the proof cannot claim a rule its gate did not fire.
  - **Unit E** (static, in `run-selftests.js`): every root-launched gate (a build step states `not-a-gate: <reason>`
    in its header) uses the registry (JS: requires `lib/gate-rules`; its code exits only through `rules.exit` or with a
    literal 0/2; shell: sources the lib and exits through `gate_exit`), and has a proof that LAUNCHES it through the
    shared helper (the helper call names the gate by `path.join(__dirname, '<gate>')`, which `what-runs` reads).
- **D3 widened to the whole env family** (owner): flags for everything that selects or injects what a rig runs —
  `--prelude=`, `--audit-prelude=`, `--audit-dir=`, `--audit-echo`, `--chrome-args=`, `--retainer-confirm`,
  `--fuzz-atlas`/`--fuzz-seed=`/`--fuzz-max-ms=`, `--src=`. Operational env stays (`FIZZYGUM_KEEP_STALE_BROWSERS`,
  `FIZZYGUM_FAILURE_IMAGES_DIR`, `FIZZYGUM_ALLOW_STALE_BUILD`). `what-runs.js` learns `--prelude=<x.js>` (and
  `--audit-prelude=`) as a launch so audit-one.sh's instrument stays in the run set.
- **Execution order (a deviation from §4, recorded):** the rails (A), the registry conversion (E's gate side) and the
  proofs (B) land PER FAMILY, not as three passes over all 45 files: a rail or a registry edit is proven by its
  family's proofs the moment it lands, instead of after 45 files. Order: shared libs (rail helper, registry, proof
  helpers, each with its own self-test) → F1 → F2a → F2b → F3 (unresolved-sends waits for Unit C) → Unit C → the
  tests-repo node gates (#29–#33, doc-narration, refs) → the D3 flag conversion → the leg proofs (Unit D) → Unit E's
  meta-check → Unit F. Each family: edit; byte-identical pass output on the real tree (diffed); each new proof alone;
  seen failing twice (§5); then `fg build`. `fg presuite` after each family that touched a runner.

### §8.4 Landing log (per family)

- **Shared libs (2026-11-07).** `lib/gate-rules.js` (+ self-test, 14 cases: every exit path, a gate required as a
  library leaves its host's exit alone, only a `.fired(` in CODE names a rule); `lib/cli-args.js` gains `dirArg`,
  `fileArg`, `rejectPositionalArgs` (+ self-test, 13 cases); `lib/planted-src.js` gains `plantedTree` (a copy or an
  empty tree, `edit`, `reset`), `proveGate` (control + planted runs, per-rule `bites <ID>` cases, fires-only-its-plants,
  every-rule-planted; `runs` may be a function of the control; `cases` joins an existing case set), per-run `args`
  (+ self-test, 8 cases: a missed rule, a wrong rule, a neighbour tripped, a failing control, an edit that matched
  nothing and a leaked plant each FAIL the proof). Neutralisation driver: `Fizzygum-tests/.scratch/every-gate-bites/
  neutralise-preload.js` + `neutralise.sh` (modes all / feed / one:<run>:<plant>; FEED_RUN picks the run fed).
  Baseline of every gate's real-tree output: `.scratch/every-gate-bites/baseline/` (`snap.sh`).
- **F1 (#13–#18, #26).** Each gate: rail + registry; its proof seen failing (all / feed / per plant). Masks fixed:
  trailing-whitespace CRLF; stringified-scripts any string spelling (paren, `'''`, one-line); region-markers per-hit
  line + dead tighten branch removed; source-vault src-rooted keys, paren-less `Object.keys window` (and NOT a table on
  the window), stale header rewritten; relayout-repaints any containing spelling + a NOTE when the harness is absent.
  Real-tree output byte-identical for all seven.
- **F2a (#2–#5, #10).** build.py `--list-shippable` gains `--src=`/`--parts=` (printed paths stay `src/…`; refused
  without `--list-shippable`, empty or missing); buildProfile `loadParts(path)`. Syntax: rail threaded through meta,
  boot and the listing; class parse errors now report the FILE line (the fragment's failing text located in the
  file); the dead `nil` shim parameter removed; proof on a mini tree (meta + boot + plants, 0.6 s). Coverage: rail +
  build.py's, fix advice rewritten for parts.json. Layering: rails `--src=`/`--tests-dir=`, src-rooted keys, 30 rule
  ids (+ declared O/Q stale ids — the proof caught them undeclared), ONE-LINE METHODS NOW CHECKED (checkFile, wrapper
  discovery, [T]: real tree still green, 85 wrappers), [D]'s marker no longer crosses a heredoc boundary, [D]'s
  toolkit half runs without the tests repo, a new `E_STALE_VALVE_EXEMPTION`, the pass line names T. Invalidation:
  `this._changed()` is a self-call. Argument-holes: census `srcSources(dir)`, proof on a mini tree sized from the
  gate's own BASELINE. Real-tree output byte-identical except layering's pass line (`/T`).
- **F2b (#11, #12, #19, #20, #22, #23, #27, #28) and the three G gates (#21, #24, #25).** install-edges `installEdges(src)`;
  pointer-handlers' problems carry their kind. Masks fixed: thin-wraps gains `STALE_EXEMPT_MARKER` and the 9 markers
  that excused nothing became plain comments (DivisionStackLayoutSpec ×4, VerticalStackLayoutSpec ×3, WorldWdgt
  resetWorld, CaretWdgt); ctor-build reads a one-line constructor and ends a constructor at a class-side key;
  relayout-bounds-first counts a delegation only when no own-geometry read precedes it, ignores `super` in a string,
  footer corrected; conformance reads compound/`or=` writes (real tree still 0/0); raw-pointer's dead
  `SKIPPED_CLASSES` stale branch removed (the table check already fails first); plane-discipline A reads compound
  writes, `B_STALE_NON_WIDGET_ROOT` declared unplantable (empty table); menu-actions reads a wrapped verb signature and
  a one-line verb's body; part-edges refuses positionals and fails (exit 2) a member half that saw no install edge.
  Proof timings: part-edges 2.6 s (2 runs), menu-actions 1.5 s, layering 1.6 s, call-separation 1.0 s (was 1.6 s).
  The existing engine self-tests of part-edges stay, the gate-run proof appended to the same file (`cases: t`).
- **F3 (#1, #6, #7, #9) and the node pool.** run-selftests gains `--umbrella=DIR` (a miniature workspace written in tmp
  at run time; the switch literal assembled so the proof never holds it). Stinks: rail with `--list <id>` kept, a rule
  per stink id plus SANCTION_COUNT / STALE_SANCTION / STALE_EXCLUDE; the plant is sized from the control's printed
  counts (`runs` as a function of the control); `comment-meta-edit`'s `to be clear,` now matches prose;
  `instanceof-type-test` tightened 75 → 74. Dead-methods: rail (refused beside `--update-allowlist`), five rules; the
  stale-entry plants name real allowlist entries read at run time. Hand-lists: rail, the four sanction tokens + the two
  list rules; a `--files` plant no longer vouches for its own sanction (old code: "1 sanctioned", new: fails — seen).
  The E-kind engine tests stay, each gate-run proof appended to its file. **NODE_POOL 4 → 8** (measured: 5.7 s → 4.3 s,
  48 self-tests, 16 cores at load 5; the tier's budget is 6 s idle).
- **Unit C (D4a) — the callable-only harvest.** `lib/name-definitions.js`: a definition is a header (`name:`/`@name:`,
  any indent, an arrow after a PAREN-COUNTED parameter list, or a signature wrapped after its `(`, or a `\`
  continuation), a prototype extension, an expando function, or a TOP-LEVEL function (column 0); the catch-all key form
  and indented locals are gone (7039 → 2856 names). Residue exactly as Unit 0 predicted: `overridingContextMenu` and
  `drawFunction` allowlisted (property-held closures), `Array.from` → bare `from`; zero other new entries.
  check-part-edges' full output byte-identical before/after (no verdict moved). Engine cases restated (+6: class-side,
  one-liner, paren default, wrapped, continued; data key, @-assignment and an indented local are NOT definitions).
  Proof: every callable `close` renamed in a copy (only `Widget.close`) while FrameWdgt's data key stays → the planted
  `w.close()` FAILS; counterfactual seen: the OLD harvest on the same copy leaves it resolved. Also proven: the
  allowlist, BUILTINS and PLATFORM_GLOBALS stale rules, BUILTINS_NOT_KEYED, KEYED_NOTHING_TO_UNMASK,
  PLATFORM_GLOBALS_NAMES_FIZZYGUM; BUILTINS_KEYED_OFF_PLATFORM declared unplantable (both sides in-file constants).
- **The tests-repo build gates (#29–#33) and the refs leg.** tests-syntax: `--tests-dir=`, `process.execPath`, an
  unrunnable node is exit 2, header's size corrected (proof on a fixture tree, 7 cases). macro-source-discipline:
  `--tests-dir=`, zero scanned tests is exit 2, MACRO SPANS READ BY THE JS LEXER (`js-mask` templates): counterfactual
  seen — a lone backtick in a JS comment made the old pairing miss the real `@evaluateString` and false-report a
  mid-name "Macro" on the JS variable. check-refs: `--tests-dir=`, a whole tree with no reference is exit 2, the pixel
  half's failures named as rules (PIXEL_HASH_MISMATCH, PIXEL_UNVERIFIABLE_REFERENCE, PIXEL_NO_REFERENCES; accounting
  mismatch and CANNOT READ declared unplantable); the pixel checker prints its skip lines under `--check-only --quiet`
  (its verdict pointed at lines it hid); the proof builds its tree from ONE real reference (copied, renamed,
  tampered). check-visualisations: `--strict` now works beside `--tests-dir=` (`renderVisualisation(test, tests)`), an
  undefined render is stale; the old acceptance corpus rewritten onto proveGate, `--strict` proven on a copied real
  test one byte off, its untouched copy passing. aim-census: `AIM_CENSUS_SRC` RETIRED for `--src=` / `--tests-dir=`
  (read at load, only from its own command line); CLASSIFIED_TWICE and UNSETTLED_DERIVATION declared unplantable.
  doc-narration: `--docs=` (refused beside `--write-baseline`), a rule id per narration label, a risen file's lines
  printed and fired, zero docs is exit 2, the-then/old- rule reaches stripped inline code.
- **D3 — the env rails become flags (the whole family, owner round 2).** `Fizzygum-tests/scripts/lib/page-rails.js`:
  `refuseRetiredEnvRails` (PRELUDE_JS, AUDIT_PRELUDE, AUDIT_DIR, AUDIT_ECHO, AUDIT_CHROME_ARGS, AUDIT_RETAINER_CONFIRM,
  AIM_CENSUS_SRC, FUZZ_ATLAS, FUZZ_SEED, FUZZ_MAX_MS set ⇒ exit 2, naming the flag that replaced each), `scriptArg`
  (empty, doubled or missing ⇒ exit 2), `installPrelude`; `lib/prelude-from-env.js` deleted. The three runners
  (`--prelude=`, `--audit-prelude=`, `--audit-dir=`, `--audit-echo`, `--chrome-args=`, `--retainer-confirm`; the
  suite runner's `--prelude` no longer needs `--tests` — a flag cannot leak into a later run; `--audit-dir`/
  `--audit-echo` without an `--audit-prelude` are refused, they would change nothing), the five page rigs, both
  serialization rigs' `--fuzz-atlas`/`--fuzz-seed=`/`--fuzz-max-ms=` (`lib/atlas-fuzz.js` `fuzzFromArgs`: a tuning flag
  without `--fuzz-atlas`, or a non-integer, ⇒ exit 2; the file rig also gains `--prelude=` and refuses stray
  arguments), the three shell gates (`parse_gate_args` takes `--prelude=`; `GATE_TESTS_ARG` → `GATE_RUNNER_ARGS`) and
  `run_audited_suite`, audit-one/run-audit-loop, the revisit/storage/vm-truth gates (vm-truth gains `--out=`, so a
  run beside the gauntlet leg no longer shares its fixed audit dir), `gate-bite-proof.js` (the plant rides the
  gate's command line; an exported env rail makes the runner refuse rather than plant the control), the two headless
  self-tests, derive-inspector-churn-set (its env scrub replaced by the refusal), run-atlas-fuzz, and every prelude's
  usage header. The runner consts named after the env vars were renamed (`AUDIT_OUT_DIR`, `ECHO_AUDIT_LINES`,
  `EXTRA_CHROME_ARGS`, `RETAINER_CONFIRM`) so a leftover sweep reads clean. `what-runs.js`: a flag value after an
  interpreter already read as a launch, so `--prelude=x.js` needed nothing; the ASSIGNMENT launch rule (`X=x.js node …`)
  is DELETED — no runner takes a script that way any more — and its fixture now asserts such a script reads as NOT run
  (counterfactual seen: the old reader fails it). Real run set unchanged (171 = 171). fg needed no edit (it exports
  none of the family).
  Verified: node tier 53 self-tests; `fg build`; `fg presuite` (dpr1 94 s, paint 150 s, fracplane); the webkit single
  test; the headless tier — all 8 bite-proofs green through the flags (74 s idle).
- **Unit D, shared machinery.** `Fizzygum/buildSystem/lib/prove-rules.js` is the ONE judge (+ self-test, 9 cases, two
  neutralisations seen failing): `proveGate` delegates to it, and the tests repo's `lib/gate-bite-proof.js` gains
  `proveLeg` on the same judge (a page plant as TEXT, written to a temp file, riding the leg's `--prelude=`; a
  `PLANT_NOT_APPLIED` console line fails "every plant applies"). A planted run may read INVALID (`exit: 2`): judged as
  INVALID, never counted as a rule. The shell twin of the registry is `gate_rules_init` + `gate_rule <ID> "line"` in
  `lib/audited-suite-with-infra-retry.sh`, its exits decided in an EXIT trap (a deviation from §8.2's `gate_exit`: a
  trap counts every exit path, as the JS exit listener does), ids read from the script's own `gate_rule` words
  (+ `lib/gate-rules-sh-selftest.js`, 11 cases, two neutralisations seen failing).
- **The suite fail-gate (run-all-headless).** Registry: the five harness FAIL families, the 23 gate tokens +
  UNTOKENIZED + UNCAUGHT, `UNLISTED_TOKEN_CONSOLE_ERROR` (an error line led by any other capitalised word — the proof
  found a `SHA256 …` line, a NOT_GATED not-distinctive word, filed under a token nobody declared: the words are
  open-ended), STALLED, UNEXPLAINED_FAILURE, SHARD_SHORT; SHARD_INCOMPLETE unplantable. Rules fire from the summary, so
  the RESULT block is byte-identical. MASK FIXED: a shard whose page listed fewer tests than its chunk read `[ok]`
  (§14 item 1) — it is now `[SHORT — …]`, fails the run, and `suite-summary.js`'s CLI counts it apart
  (`SUMMARY_SHORT`) so the audit gates' infra retry never reads a finding as a dropped shard. HARNESS DEFECT FOUND BY
  THE WEBKIT HALF: a command exception's FAIL line printed `error.stack` alone, and JavaScriptCore's stack carries no
  message, so on the webkit/finger legs it never said what threw (`AutomatorPlayer.coffee`: message, then stack).
- **The three shell gates.** Rules named (`EMBEDDED_SUITE_FAILED`, `INSTALL_GAP` on all three; tier-naming
  `FAMILY_OUT_OF_STEP`, `LEAF_ARRANGE_VIOLATION`; settle `SETTLE_IN_CALLBACK`; capstone `CARELESS_PUSH`,
  `PAINT_TIME_SCHEDULE`, `UNCLASSIFIED_RECORD`). MASK FIXED (§14 item 18 and wider): a test that played with no audit
  bucket was invisible to every count (tier-naming and settle never checked; capstone re-ran it through audit-one.sh,
  which dropped any plant) — now `require_every_bucket` in the shared lib reads it INVALID on all three, and the
  capstone backfill is deleted (with the SHARD_SHORT rule and the infra retry, a missing bucket after a passing suite
  is a lost marker, not a dropped shard). audit-one.sh's third (prelude) argument went with it.
- **The other audit gates and the leg rigs (Unit D, cont.).** Each proof seen failing under the leg neutraliser
  (`.scratch/every-gate-bites/neutralise-leg-preload.js`: the control fed the first run's planted inputs, every run
  stripped of its own — plants AND rail inputs such as a baseline or an audit dir — so every "bites" case fails and
  only the vacuous "fires only the rules it plants" survives).
  - revisit: `--baseline=FILE` rail (refused beside `--write-baseline`) makes the VANISHED direction plantable; drift
    split into NEW_SIGNATURE / VANISHED_SIGNATURE; a runner refusal is exit 2, a failed suite EMBEDDED_SUITE_FAILED.
  - storage: one rule per finding KIND, read from the prelude's own `findings.push('<kind>:` literals (9) +
    UNKNOWN_STORAGE_FINDING + EMBEDDED_SUITE_FAILED — all 9 kinds planted (the residue plants exist only DURING the
    audit: made in its first act, taken out at its STORAGE-AUDITED line — a world carrying a parent-less child trips
    the reset's last-rites seat and the test never starts; measured: a 5-min hang).
  - vm-truth: `--out=`; registry; a CAPPED suspect list is now INVALID (was a warning — a dropped suspect is an
    unanswered one); RETAINED_WORLD / RETAINED_WIDGET end to end through both tiers (a closure on the boot world, two
    tests in ONE shard — a shard's last test is never swept; the widget made AND destroyed inside one test, so the
    in-band inventory cannot see it); HEAP_FLOOR / UNKNOWN token / WORLD_NOT_REPLACED / capped on fabricated audit dirs
    through `--audit-dir=` (no browser).
  - menusweep: kinds read from its own `kind: '…'` literals; CONSOLE_ERROR (MASK FIXED: console/page errors now fail —
    a green sweep prints none); the five vacuity rules planted by one run that keeps every root buildable (one row per
    menu, no dots/flags, no class for the contributor derivation) — its knock-on SUBMENU_FLAG_MISMATCH /
    ELLIPSIS_MISMATCH / ROOT_UNBUILT expected with their own lines.
  - pinsweep: kinds from its own literals; CONSOLE_ERROR reported beside violations (was only without them);
    PIN_CHECKS_VACUOUS floor 2000 (a full run checks ~2,700); `.catch`.
  - graph: `--prelude=` rail (it had none); one rule per SECTION + STORAGE_INVARIANT + CONSOLE_ERROR; `.catch` exit 2.
  - census: console listener (MASK FIXED); each offender on its own line, named by its rule (capped at 20 per kind);
    `exitWhenFlushed` — the proof found the report CUT: a thousand mover lines then `process.exit`, the lines after
    them (and the RULES line) lost on the pipe; gate-rules' exit hook now retries its write on EAGAIN (`writeAll`).
    STALE_KNOWN_MOVER and NO_TARGETS unplantable (stated).
  - paint: `--tests=` / `--prelude=` rails; OFFENDER, COVERAGE_HOLE, FAILING_CONSOLE_LINE (MASK FIXED: page errors now
    fail, through the runners' own fail-closed rule — a DATAFLOW_ERROR is data and passes); `auditWasOn` (read back
    the flag the script itself set) replaced by "checked nothing" = INVALID; both paths judge coverage.
  - apps: `--apps=` / `--prelude=` rails; DISCOVERY_ERROR (MASK FIXED: the discovery page had no listeners),
    BOOT_ERROR (launch pages' boot errors were excluded), DISCOVERY_SHORT (APPS_FLOOR 12; 15 today, the Examples
    folder's 5 the group a broken folder loses), LAUNCH_THREW, ERROR_DURING_LAUNCH; WORLD_NOT_READY / NO_ICON stated
    unplantable.
  - parts ×3: `--prelude=` rails; one rule per SECTION; a step that throws is INVALID; lazy-load's `[SKIP] window.gc`
    is INVALID (the browser is launched with --expose-gc for it); snapshot-load MASK FIXED: the loading page's
    (page b's) errors were never collected.
  - serialization (round trip): its TABLES moved to `lib/serialization-expectations.js` behind an
    `--expectations=FILE` rail, `--sections=` (samePage / crossSession / everyApp / teardown / world). MASK FIXED: 32
    reported names were held to nothing (a name absent from EXPECTATIONS defaulted to expected-true, so it could stop
    being reported unseen) — the 17 fixed names joined EXPECTATIONS, the 15 per-app ones are a DYNAMIC_FAMILY
    (`world.everyAppSnapshot.`), and a reported name neither holds is UNDECLARED_CHECK. Rules: CHECK_MISMATCH,
    UNDECLARED_CHECK, UNREPORTED_EXPECTATION, STALE_DYNAMIC_FAMILY, STALE_SWCANVAS_ONLY_CHECK, SW_ONLY_UNNAMED,
    FAILING_CONSOLE_LINE (MASK FIXED: page errors were a note; console errors were read only under --verbose — now the
    runners' fail-closed rule; a green run prints only DATAFLOW_ERROR, by design). A --sections run judges the names
    the in-page functions it CALLED spell (bootPage records each page.evaluate), plus an unspelled name under a parent
    path it reported (the 11 composed names stay out). The proof plants a perturbed copy of the tables — every verdict
    rule from one same-page run on both backends. The full rig is green with the new rules.
  - serialization (file): `--prelude=`, rules FILE_CHECK_FAILED / FAILING_CONSOLE_LINE (console lines now counted).
  - run-sequence (`fracplane`): MASK FIXED — the completion wait's result was ignored, so an unfinished sequence read
    as a pass; it is INVALID now (exit 2), with a `--complete-secs=` rail (default 180) so the proof sees it in 25 s.
  - Findings on the way: the census's report was CUT by `process.exit` after a thousand lines (above); a quote inside
    a regex literal (`/kind: '…'/`) threw the tests-repo code reader's masking out of step, so later names read as
    code; and a plant's computed access on a named class (`StringWdgt.prototype[k]`) told the call-separation census
    it reached every method of the chain — a plant now reaches its one setter through a local prototype.
- **Unit E — the gate census (run-selftests.js, the build's node tier).** `lib/what-runs.js` `runSet` gains `how`
  (root / launched / required / discovered). Every LAUNCHED script that is not an instrument (`*-prelude.js`) is a gate
  unless its header says `not-a-gate: <reason>` (6 stated: build.py, buildProfile.py, the two generators, the reference
  recompressor check-refs judges, the sourced shell lib); a gate must name its rules (GATE_WITHOUT_REGISTRY) and be
  LAUNCHED by a self-test that uses a proof helper (GATE_WITHOUT_PROOF). Real workspace: 53 gates, all green. Its own
  proof: run-selftests-selftest's miniature (a gate with no proof, one with no registry, a stated build step); and the
  counterfactual on a scratch copy of the workspace — pin-sweep's proof removed, check-tests-syntax's registry removed
  — named exactly those two. ⚠ A scratch copy of the workspace under `Fizzygum-tests/.scratch` is READ by
  call-separation and hand-lists as tests-repo code: delete it before a build.
- **Budget (measured).** Node tier 54 files, 969 cases, 4.6 s at NODE_POOL 8 (≤ 6 s). Headless tier 22 files, 362
  cases, ~750 lane-seconds: 261 s at HEADLESS_POOL 3 (idle), 152.9 s at 6 (idle) → HEADLESS_POOL 6; the in-wave time
  is read off the closing gauntlet.
- **A finding the rewrites exposed:** call-separation's [U] went red on `PenWdgt.tree` — the old
  check-visualisations self-test's `c.tree` had been its only "outside reference" (a coincidence of names). `tree` is
  `sierpinski`'s sibling turtle demo op (user scripting), so it joins `public-api-allowlist.txt` with that reason.
  ⚠ For the review: the owner triaged that allowlist before; this entry is the arc's call.

### §8.3 Masks found by Unit 0, and their disposition

Rule (§6): fix a bounded one in its family, with a plant in its proof; file an unbounded one with its measurement.
**Fix in the arc:** empty `--src=` accepted (C1); source-vault: paren-less `Object.keys window`, stale header;
region-markers: a per-hit line; trailing-whitespace: CRLF; relayout-repaints: `\b` misses `_disableTrackChanges`;
tests-syntax: exit 2, `process.execPath`, stale header; macro-source: exit 2, zero-test vacuity, backtick pairing (use
`js-mask` templates); thin-wraps: a stale-exemption rule (9 markers excuse nothing today); layering: one-line methods
checked, [D] sanction leak, [D] src half without the tests repo, [E] valve stale check; invalidation: `this._changed()`
is a self-call; stinks: `comment-meta-edit`'s `to be clear,`, `instanceof-type-test` 75 → 74; menu-actions: RULE 3 on
a wrapped signature and a one-liner, the dead UNDER branch; part-edges: a member-half vacuity floor, a positional
refusal; conformance: `?=`/`+=`/`or=` writes; relayout-bounds-first: a read before the delegate line, `super` in a
string; plane-discipline A: compound writes; check-refs and doc-narration: a run that scanned nothing exits 2;
doc-narration: the dead backtick branch; check-visualisations `--strict`: an undefined render; hand-lists `--files`:
a planted `.coffee` vouching for its own sanction; the leg rigs: menusweep and census and serialization fail on
console/page errors, paint's error/serial/flag holes, parts-snapshot page b's errors, apps' discovery listeners and app
floor, pinsweep's floor and `.catch`, graph's `.catch`, `run-all-headless`'s shard-sum check, vmtruth's fixed out dir,
run-sequence's ignored completion wait, the 21 names missing from serialization's `EXPECTATIONS`. (Each tightening
can expose real violations in the tree: investigate before ratcheting.) Disposition on landing: menu-actions' UNDER
branch is REMOVED — `RULE3_BASELINE` is 0, so `unread.length < 0` could never run it (an earlier pass misread it as
the live tighten-note of a nonzero ratchet; the constant settled it).
**File (unbounded or heuristic by design):** invalidation's `#`-in-string cut; argument-holes reading strings as
code (shared with the census parser); raw-pointer's column-0 and line-wide `MAPPED` heuristics; the suite's
infinite-JS-loop watchdog gap; serialization's unreported-expectation rail; vmtruth's heap floor on a short run;
run-selftests walking `__pycache__` (fixed at the close: the walk skips it, like `what-runs.js`'s).

### §8.5 The closing gauntlet and the end-of-arc review (2026-11-07)

- **Closing gauntlet #1: 20/20, OK with a warning, 1052 s.** `selftests` 217 s in-wave against wave A's longest leg
  (dpr2, 221 s): inside the budget. `apps` FAILED in-wave and passed alone: the discovery page's 15 s ready wait expired
  under the wave-A boot storm (HEADLESS_POOL 6 puts more browsers into that wave), and `discoverApps` ignored the wait's
  answer, dereferencing a world that was not there (a TypeError; the rig's catch exits 2, and fg flattens the apps leg's
  non-zero exit to 1). Fixed: a discovery page whose world never became ready is INVALID with its own line, and the
  ready wait is 60 s (a quiet boot is about 3 s).
- **The review (one fresh agent, read-only, goals and diffs): no HIGH finding.** Each one, and what was done:
  1. SHARD_INCOMPLETE was declared unplantable, falsely: a second planted run per browser (every test's world stops,
     `--max-stalls=1` abandons the shard at its second stall, a test still left) plants it. Same class, also false:
     apps' WORLD_NOT_READY and NO_ICON, the census's NO_TARGETS — all planted now (a launch page told from the discovery
     page by the 1024-wide viewport only launch pages get; a world whose assignment is swallowed, on a clock that runs
     fast so the 60 s wait ends at its first look; a `children` accessor answering empty only inside `sweepInto`), and a
     third apps run proves the discovery INVALID. Every one of those unplantable lines is deleted.
  2. Five passages in three gate headers still described the deleted catch-all definition form (check-unresolved-sends
     ×2, check-part-edges ×2, check-hand-lists): rewritten for the callable-only harvest; part-edges' states its one latent case (a DATA field
     a harness installed and core also declared would read as the harness's symbol; none does).
  3. The census read a script by the FIRST edge that reached it, so a launched script a `require` reached first escaped
     (`suite-summary.js`, which the shell lib launches). `what-runs.js` now marks a script launched when ANY edge launches
     it. That exposed a heuristic launch (`check-hand-lists.js` builds its own self-test's path, to skip it), and the
     answer is the class: a self-test is a proof, judged by run-selftests' own SELFTEST_* rules, so the census leaves the
     self-tests out as it does the preludes. `suite-summary.js` states `not-a-gate:` (a reader its gate judges).
  4. `require_every_bucket` expected a bucket for every test DIRECTORY, while the harness may drop a test before playing
     it (`SWCanvasBrokenTests`): one entry there would have read INVALID on all three shell gates. An audit run of
     `run-all-headless.js` now writes `_tests-to-play.txt` (its probe's list) beside the buckets; `require_every_bucket`
     and `run-audit-loop.sh` read it; a run that left none is INVALID.
  5. A value flag written with a space (`--prelude FILE`) was silently dropped: the run went unplanted. Fixed for the
     class in the shared readers — `lib/cli.js` `flagValue`, `lib/page-rails.js` `scriptArg`, Fizzygum's
     `lib/cli-args.js` `dirArg`/`fileArg` refuse it (exit 2), each seen failing; run-all-headless's own bare-`--tests`
     refusal is deleted as redundant.
  6. check-refs re-wrote the pixel half's buffered output, then `process.exit`: `exitWhenFlushed` now.
  7. The shell registry accepted an id it never declared (a computed one): `gate_rule` refuses it, exit 2.
  8. "An INVALID run fires no rule" was unverifiable — the RULES line printed on exit 1 only. Both registries print it on
     an exit 2 that fired a rule (the exit kept), and `prove-rules.js` no longer counts an INVALID run toward coverage.
     vm-truth: a CONVICTED retention now fails (exit 1) even when the run was also incomplete, the gap printed beside
     it; incompleteness alone stays INVALID (a new proof run: a climbing floor beside a capped suspect list).
  9. The census accepted a proof helper required but never called, and a `not-a-gate:` line anywhere in a file: it now
     needs a `proveGate`/`proveLeg` call in code, and the line in the file's HEADER (both seen failing).
  10. fg's `selftests` comment updated (fg backed up first: scratchpad `fg.before-every-gate-bites`); name-definitions'
      and the `tree` allowlist entry's dated notes made present-tense; `aim-census.js` now REFUSES `AIM_CENSUS_SRC` (it
      ignored it). `lib/cli-selftest.js` gains standing checks: every retired env rail refused, every `scriptArg` caller
      also refuses them, no script but `page-rails.js` reads one (each seen failing).
- **The tier after the fixes, and its schedule.** The review's plants added five runs (suite-gate +2, apps +2, census
  +1, vm-truth +1 without a browser): 22 files, 389 cases, 193.8 s idle at pool 6 in discovery order — but ~870
  lane-seconds is ~145 s of work per lane: the rest was the 97 s suite-gate proof starting LAST. `run-selftests.js` now
  starts files longest-first, by the seconds each took on the previous run (`longestFirst`, a scheduling hint in the OS
  temp dir; a file with no time starts first; reports still print in discovery order).
- **Closing gauntlet #2: FAILED on one leg, `selftests` (19 of 20 passed, 1165 s).** In-wave, the tier-naming proof's
  CONTROL hung: its one-test suite showed 0/1 for five minutes until the proof's 300 s run timeout killed it (the leg
  330.5 s). The run's out dir was deleted with it, so nothing says why; a page that never yields (the shard's poll
  waits on it: §8.3's filed watchdog gap) fits, and is not shown. On its serial retry the leg passed tier-naming and
  failed instead on the parts-lazy-icons proof, whose rig printed only `errors[0]`: an earlier error (most likely a boot
  error under load) hid the plant's line. Fixed: the rig lists every error under its FAIL line, as its two sibling
  parts rigs do, and the proof finds the plant's line among them (its regex checked against an earlier error, an
  absent plant line and a plant line in a later section); and a proof run its timeout KILLS now keeps its files and
  prints the head of its output (`gate-bite-proof.js` `killedNote`), so a recurrence says what it was doing.
- **Closing gauntlet #3: 20 of 20, no warning, 941 s** (Fizzygum and Fizzygum-tests at their reviewed trees, both
  uncommitted). `selftests` 212 s in-wave against wave A's longest leg (dpr2, 224 s): inside the budget. Node tier
  54 self-tests, 996 cases, 4.7 s (budget 6 s); `npm run selftest` 16 self-tests, 287 cases; presuite and the webkit
  single test green before it. `fg homepage` not run: no change to `build_it_please.sh`, `src/boot` or `src/meta`.
- **The owner choices, read independently:** the `tree` allowlist entry, the nine thin-wrap markers made comments, the
  capstone backfill's deletion (finding 4 applied) and the deleted assignment launch rule: sound. HEADLESS_POOL 6: sound,
  its in-wave time measured at the closing gauntlet (above).

---

## BACKLOG ledger

The two items this arc closed, as BACKLOG held them:
- [x] **Only the gates whose rules were proven BY HAND have a bite-proof; most gates have none.** The arc's class was
      "a rule proven by a planted violation once, at authoring" (the rules of eight gates). The broader
      question, whether every gate the build or a gauntlet leg runs must carry a standing proof that its rule bites
      (the 33 static gates mostly have none, and several have no self-test at all), is an audit of its own: survey the
      gates, say which rules a plant could prove, and rule on whether the build should require one per gate (plan §8,
      "a meta-rule"). (Section "archive/bite-proofs-plan.md".) — CLOSED: Units 0, A–E; the census (Unit E) is the
      meta-rule.
- [x] §4 **The unresolved-sends DEF harvest's catch-all form is a second mask** — `check-unresolved-sends.js` counts any
      `name:` / `name =` key or local as a definition, so a data key or local of a name (`close:` in a theme table, a
      local `add = ->`, `entries = []`) keeps every call of it resolved after every real method of that name is gone:
      `close`, `add`, `get`, `clear`, `entries` (32 Fizzygum-receiver sites at the census). A callable-only harvest
      would close it but must first learn the 67 method headers whose default value holds a paren (`clear: (color =
      (…)) ->`), which only the catch-all form catches today. (Section "archive/hand-lists-residue-plan.md".) —
      CLOSED: Unit C (the callable-only harvest, its bite-proof seen failing on the old harvest).

Filed by this arc: the heuristic masks of §8.3 "File" (BACKLOG, section "archive/every-gate-bites-plan.md").

---

## Appendix A — measuring the unresolved-sends mask (re-run before Unit C)

Save as `Fizzygum-tests/.scratch/bite-meta/def-mask.js` and run it with `node` from the tests repo:

```js
const fs = require('fs'), path = require('path');
const ROOT = '/Users/davidedellacasa/code/Fizzygum-all', B = ROOT + '/Fizzygum/buildSystem';
const { stripComment, DEF_FORMS } = require(B + '/lib/name-definitions.js');
const { harvestCalls } = require(B + '/check-unresolved-sends.js');
const walk = (d, a = []) => { for (const e of fs.readdirSync(d, { withFileTypes: true })) {
  const p = path.join(d, e.name); if (e.isDirectory()) walk(p, a); else if (p.endsWith('.coffee')) a.push(p); } return a; };
const files = [...walk(ROOT + '/Fizzygum/src'), ...walk(ROOT + '/Fizzygum-tests/Automator-and-test-harness-src')];
const HDR = /^\s*@?([A-Za-z_$][\w$]*)\s*:\s*(\(.*\)\s*)?[-=]>\s*$/;   // a header, incl. class-side and paren defaults
const callable = new Set(), dataOnly = new Map();
for (const f of files) for (const raw of fs.readFileSync(f, 'utf8').split('\n')) {
  const line = stripComment(raw); let m, c = false;
  for (const r of DEF_FORMS.slice(0, 5)) if ((m = r.exec(line))) { callable.add(m[1]); c = true; }
  if ((m = HDR.exec(line))) { callable.add(m[1]); c = true; }
  if (!c && (m = DEF_FORMS[5].exec(line))) (dataOnly.get(m[1]) || dataOnly.set(m[1], []).get(m[1])).push(path.basename(f) + ': ' + line.trim());
}
const sent = new Map(); for (const s of harvestCalls(files)) sent.set(s.name, (sent.get(s.name) || 0) + 1);
const masked = [...dataOnly.keys()].filter((n) => sent.has(n)), n = (l) => l.reduce((a, k) => a + sent.get(k), 0);
const withReal = masked.filter((k) => callable.has(k)), only = masked.filter((k) => !callable.has(k));
console.log({ files: files.length, masked: masked.length, maskedSites: n(masked), withReal: withReal.length,
  withRealSites: n(withReal), onlyData: only.length, onlyDataSites: n(only) });
console.log(only.map((k) => k + ':' + sent.get(k)).join(' '));
```

2026-11-07 output:
`{ files: 586, masked: 62, maskedSites: 2388, withReal: 48, withRealSites: 2337, onlyData: 14, onlyDataSites: 51 }`.
`HDR` requires the arrow at the end of the line, so the class-(i) one-liners land in `onlyData`. That is the point:
they are the definitions the new harvest must learn.

## References

- `docs/architecture/lint-and-static-checks.md`: §3 (the index, and the bite-proof paragraph), §6b (one shared method
  matcher), §7 (documented boundaries).
- `docs/archive/bite-proofs-plan.md`: §5 plants, §8 rejected alternatives, §9 ledger (review R1–R20: vacuity, shared
  output dirs, the PRELUDE_JS leak).
- `docs/archive/unrun-checks-plan.md`: `lib/what-runs.js`, self-tests found by name.
- `docs/archive/hand-kept-lists-plan.md`: why the meta-rule must be derived.
- `buildSystem/check-unresolved-sends.js` header: "THE SOUNDNESS TRADE" and "KNOWN GAPS".
- Memory: `bite-proofs.md`, `unrun-checks.md`, `hand-kept-lists-tier34.md`.

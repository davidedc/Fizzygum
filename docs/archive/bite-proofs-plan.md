# Standing bite-proofs for the checks proven only by hand

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.** Status: AUTHORED 2026-11-07;
owner decisions D1–D5 RULED 2026-11-07, all (a) (§3, §9). **CLOSED 2026-11-07** — Units 0, A, B, C done; the end-of-arc
review's R1–R20 all fixed; gauntlet 20/20. Ledger: §9.

**Mandate: eliminate the class, not patch instances.** A gate whose RULE was proven to bite by a planted violation
ONCE, at authoring, and never again, can stop biting and stay green. Every such rule gets a standing bite-proof that
runs at a tier (the build or the gauntlet), so "this gate catches X" is re-proven at every commit point. A by-hand plant
recipe left in a header is the defect, not a substitute.

## §0 Orientation

- Fizzygum is a CoffeeScript GUI framework. `Fizzygum/` holds the source and the build (33 static gates); `Fizzygum-tests/`
  holds the SystemTest suite (373 macro tests), the harness, and the Node tooling under `scripts/`. They are sibling repos
  under the umbrella `Fizzygum-all/`, which is not a repo. `fg` (the umbrella's local, uncommitted wrapper) runs builds
  and gates: `fg presuite` is the inner loop, and `fg gauntlet` (20 legs, ~15 min) closes a commit point.
- **Prior arc:** `docs/archive/unrun-checks-plan.md` (pushed Fizzygum `0a2620d0`, tests `ea79ebb54`) made two kinds of
  reliance run:
  - **Every self-test runs.** A self-test is a FILE, found by name:
    - `<subject>-selftest.js` is pure Node; the build's FIRST gate runs every one (`buildSystem/run-selftests.js`).
    - `<subject>-selftest-headless.js` boots the built page; the gauntlet's `selftests` leg runs every one
      (`run-selftests.js --headless`).
  - **Every sanction's guard runs.**
- **What that arc left** (BACKLOG, section `archive/unrun-checks-plan.md`) is this plan's subject. Several gates'
  own rules were proven by a plant at authoring and nothing re-runs the plant.
- **The pattern already exists once:** `Fizzygum-tests/scripts/notification-settle-audit/cache-oracle-selftest-headless.js`
  proves the `settle` leg's cached-vs-SLOW rider. It runs one test three times through the single-test runner:
  - the settle prelude plus `cache-oracle-plant.js` must FAIL on `CACHED_DERIVATION_DIVERGED`;
  - each of the two alone must PASS.
- **Critical reframe:** a bite-proof of a GATE must run the GATE. Everything that can silently stop biting sits in
  three layers:
  - the prelude's wrappers;
  - the product hooks the wrappers observe;
  - the gate's own verdict code: its greps, coverage counts and exit codes.

  A proof that runs only the prelude (the cache-oracle shape) leaves the third layer unproven. That layer is where a
  format change in an emitted line or a regrouped `grep` goes blind. §2's measurements show that running the real gate
  on a one-test subset costs ~7–8 s, against ~5 s for the prelude alone, so the cheaper proof buys almost nothing.

## §1 Survey — the rules proven only by hand (verified 2026-11-07 against `0a2620d0` / `ea79ebb54`; line numbers drift, grep the quoted text)

### §1.1 The suite audit gates

Each one:
- runs the WHOLE suite with an audit prelude, through `scripts/run-all-headless.js` and its `AUDIT_PRELUDE` /
  `AUDIT_DIR` rails;
- reads per-test `<AUDIT_DIR>/<test>.log` buckets. The runner opens a bucket at each `LAYOUTAUDIT_TESTSTART <name>`
  line, drops LAYOUTAUDIT lines that come before any, and writes a `LAYOUTAUDIT installed (sharded)` header into
  every bucket of a shard whose prelude announced itself;
- has a positive-coverage line (`…-OBSERVED`, `capstone-armed`/`paint-armed`, `STORAGE-AUDITED`), and the three
  verdicts 0 / 1 / 2 = OK / FAILED / INVALID.

None has a standing plant of its rule.

| gate (fg leg) | files (`Fizzygum-tests/scripts/`) | the rule | finding channel → verdict |
|---|---|---|---|
| tier-naming (`tiernaming`) | `tier-naming-audit/run-tier-naming-gate.sh` + `tier-naming-prelude.js` | a `__commit*` LEAF fires no react step or seam in its own frame: `if (f.seamDirect \|\| f.reactDirect) emit('leaf-fired-orchestration', f);` | the gate's `hard_corners=$(grep -h '"tag":"leaf-fired-orchestration"\|"tag":"arrange-fired-seam"' …)` → exit 1, listing `leaf-fired-orchestration <Ctor>::<method>`. Its header says it outright: *"No standing self-test plants a __commit* that REACTS"* |
| notification-settle (`settle`) | `notification-settle-audit/run-notification-settle-gate.sh` + `notification-settle-prelude.js` | [J]: a `_reactTo*`/`_before*` callback opens no flush. `wrapSettle` emits `settle-inside-callback` when `depth > 0` and the receiver is not an orphan deferring (`var orphanDefer = …`) | `violations=$(grep -h "LAYOUTAUDIT {" …)` → exit 1, `by callback: <Ctor>.<callback> opened <method>`. Its RIDER already has a proof (cache-oracle), its rule none |
| revisits (`revisits`) | `revisit-gate.js` + `audit-preludes/revisit-prelude.js` | no widget's `_reLayout` is entered twice at depth 0 in one flush (`if (depth === 0 && flushMap)`; the baseline `revisit-baseline.json` is EMPTY) | `LAYOUTAUDIT REVISIT i=… multi=…` → profile ≠ baseline → `DRIFT <test>` … exit 1 |
| storage (`storage`) | `storage-invariant-gate.js` + `audit-preludes/storage-audit-prelude.js` | at each `resetWorld` ENTRY the boot-or-previous world's storage, reclassified from scratch, proposes zero moves and holds no residue | `LAYOUTAUDIT STORAGE <finding>;…` → `storage-gate: FAILED`, exit 1. Attribution: a bucket audits the state BEFORE its test (the last test of a shard is never audited) |
| capstone (`capstone`) | `end-of-cycle-audit/run-capstone-gate.sh` + `eoc-capstone-prelude.js` | TWO rules: no careless end-of-cycle push (`"tag":"careless"`), and no layout scheduled during paint (`"tag":"paint-time"`) | each tag counted, offenders listed per test, exit 1. Both proven BY HAND in the unrun-checks arc (`Fizzygum-tests/.scratch/unrun-checks/paint-time-plant.js`, unbounded, failed both rules 31× each with the suite green) |

**And their coverage branches are in the same class.** `lint-and-static-checks.md` (the runtime audit gates section,
"⭐ **Every suite-wide audit gate now carries one**") claims each coverage assertion *"was proven by plant in both
directions — … wrappers suppressed gives `0/307` and INVALID"*. That was done once, by hand, and nothing re-runs it. ⚠
And the claim the same doc makes next, *"A coverage shortfall exits **2 = INVALID** everywhere"*, is FALSE for the
capstone: its `armed`/`paintarmed` shortfall prints `CAPSTONE GATE FAILED` and `exit 1`.

### §1.2 Static gates with a by-hand plant recipe in their header

| gate | the recipe in its header | what a standing proof must show |
|---|---|---|
| `buildSystem/check-call-separation.js` | *"To see it bite (a plant, by hand: no standing self-test runs one): add a `_foo: -> @somePublicCommand()` to a throwaway src class, confirm the count bumps past the baseline and the build aborts; `# public-call-sanctioned: fixture` exempts it."* Its call-SHAPE decisions have a self-test (`census-public-private-calls-selftest.js`); its baseline and sanction verdict has none | an unsanctioned private→public-command site fails `[S]` naming it; the marker exempts it |
| `buildSystem/check-back-buffer-memos.js` | *"Revert plant: give SimpleImageWdgt's builder a size memo (`@lastPaintedImageSize = @extent()`), or delete the `# saved-content:` line above CanvasWdgt.drawnRaster — either fails the gate naming the field."* | a builder-written field that is neither transient nor declared saved content fails naming it; the declaration passes it |
| `buildSystem/check-page-loaded-elements.js` | *"Revert plants: drop "img" from SimpleImageWdgt's @serializationTransients, or delete its _reactToBeingCopied or its _afterDeserialization … delete the page-element-not-held line … and it fails as unattributed."* | rules (a) transient, (b) both re-make hooks, and the unattributed-construction rule, each failing naming the class and field |

The survey grep (`plant`, `by hand`, `Self-test:`, `prove-it-fails` over both repos' `buildSystem/` and `scripts/`)
found nothing else in the class. `build-tree-fingerprint.js`'s "prove-it-fails drill" is a dated receipt, and it is a
compare tool `fg` runs only on demand.

## §2 Measurements (2026-11-07, idle machine, fresh build)

| run | wall |
|---|---|
| one test (`SystemTest_macroAnalogClockInspectEdit`) through the single runner with the tier-naming prelude (option D1(b)) | **5 s** |
| the same test as a one-test SUITE run, `AUDIT_PRELUDE` + a hand-edited 1-test manifest + `--keep-manifests` (what D1(a) costs: a probe boot, a shard boot, the test) | **7 s** |
| `node scripts/revisit-gate.js -- --keep-manifests` on that 1-test manifest | **7 s**, `OK … 1/1 test buckets observed` |
| `node scripts/storage-invariant-gate.js -- --keep-manifests` on that 1-test manifest | **8 s**, `OK … 1/1 test buckets audited` |
| the headless self-test tier today, `run-selftests.js --headless`, idle | **68 s** (preludes-install 49.6, cache-oracle 15.3, heap-forensics 3.4); in-wave (gauntlet wave A) **101 s**, so ×1.5 under load |
| `check-call-separation.js` / `check-back-buffer-memos.js` / `check-page-loaded-elements.js` on real src | **430 / 56 / 68 ms** |
| copying `Fizzygum/src` (5.8 MB, 561 `.coffee`) | **84 ms** |
| the node self-test tier, `run-selftests.js` | **~1 s** |

**Both JS gates' coverage holds on a one-test subset.** The three shell gates cannot be run on a subset today: they
call `run_audited_suite` with no pass-through. The capstone's shard-miss backfill would also re-run every test that
has no log, i.e. the 372 tests a subset leaves out. ⚠ The probe in `probe-callbacks.js` (§9) showed that almost every
`_reactTo*`/`_before*` callback in the chosen test runs INSIDE a mutation window (`world._inLayoutMutation` true,
`_recalculatingLayouts` false). There an ATTACHED `_settleLayoutsAfter` throws (`Widget._settleLayoutsAfter`), but a
`recalculateLayouts()` runs (`WorldWdgt.recalculateLayouts` throws only on `@_recalculatingLayouts`). That decides the
settle plant's shape (§5).

## §3 Owner decisions (one round; recommendation first)

- **D1. What a bite-proof runs.**
  - **(a) RECOMMENDED: the REAL gate, on a one-test subset, with the plant injected beside its prelude.** It proves
    all three layers (§0), at ~7–8 s a run. It needs two generic rails in the suite runner:
    - `--tests=A,B` (a FLAG: an env var exported by mistake would silently shrink every gauntlet leg to a subset that
      passes);
    - `PRELUDE_JS` (the documented plant rail every other runner and rig already honours).

    It also needs the three shell gates to pass `--tests=` through, and the capstone's backfill to stay within the
    subset (Unit 0).
  - **(b) The prelude alone, on one test, through the single runner**, with the self-test judging the prelude's lines.
    It saves ~2–3 s a run, but restates each gate's grep in the self-test, a second copy free to drift from the first,
    and it leaves the gates' verdict code unproven.
- **D2 (a specification from the brief, not a fork; stated for the record).** One plant per rule, CONFINED to one test
  that stays green under it, and BOUNDED (gotcha (e): the unbounded paint-time plant moved three tests' pixels;
  an always-wrong twin flooded ~250 k lines and misread under a loaded wave). Every plant rides
  `SystemTest_macroAnalogClockInspectEdit` (the registered example; cache-oracle and preludes-install use it too).
  Every proof also has:
  - a CONTROL: the same run without the plant must PASS;
  - a planted case that fails only on the rule's OWN report naming the plant's signature (§5), so a gate failing for
    another reason (a crashed test, a coverage gap) does not count as a bite.

  Every plant is ORDER-INDEPENDENT of the prelude it rides with. It hooks a method the prelude does not wrap, inside
  the frame the prelude does wrap, so it bites whichever installs first. Plants are named `*-plant.js`, never
  `*-prelude.js`, because `preludes-install-selftest-headless.js` installs every `*-prelude.js` on its own.
- **D3. The static gates (§1.2).**
  - **(a) RECOMMENDED: a node `<gate>-selftest.js` that runs the REAL gate as a child process** on a planted COPY of
    real `src/` (a new `--src=DIR` on the three gates, through `lib/cli-args.js`, so each also refuses unknown
    arguments). The plant is an ADDED throwaway class file, never an edit of a real holder: it bites on the rule and
    cannot drift with SimpleImageWdgt's text. Each test also runs a control (the unplanted copy passes) and the
    sanctioned or declared variant (it passes). This adds ~2 s to every build: call-separation's census is 0.43 s × 3,
    the other two ~70 ms a run.
  - **(b) Unit-level: export each gate's verdict as a function and drive it on fixture rows.** It is faster, but a
    second, in-memory picture of the census is free to disagree with the real one.
  - **(c) Keep the recipes by hand.** That is the defect.
- **D4. The time budget of the `selftests` leg.** Estimate: ~16 gate runs × ~8 s ≈ 130 s idle on top of today's 68 s,
  so ~300 s in-wave if sequential. Wave A's longest suite leg is dpr2 at 209 s, so the gauntlet would grow by ~90 s.
  - **(a) RECOMMENDED: one leg, and `run-selftests.js --headless` runs its files 3 at a time.** Each file's own runs
    stay sequential, children get `FIZZYGUM_KEEP_STALE_BROWSERS=1` (the single runner otherwise culls sibling
    files' browsers), and each file's report is printed in discovery order. Estimate: ~70 s idle, ~105 s in-wave,
    i.e. today's figure. Each future bite-proof is just another file.
  - **(b) One leg, sequential.** ~+90 s on the gauntlet's critical path.
  - **(c) Each gate's fg leg runs its own proof first.** REJECTED: the guarantee would live in `fg`, which is
    uncommitted.
- **D5. The coverage branches (§1.1, the doc's by-hand "both directions" claim).**
  - **(a) RECOMMENDED: in scope, with ONE shared generic plant**, `audit-preludes/unobserved-bucket-plant.js`. When
    the test stops, it prints a `LAYOUTAUDIT_TESTSTART` for a bucket no instrument writes into. Every gate must then
    exit 2 with its INVALID line. That proves each gate's bucket count, its per-bucket marker match (a sloppy grep that
    matched the synthesised `installed` header would pass it, and fail the proof) and its exit code. The capstone's
    shortfall moves from `FAILED`/1 to `INVALID`/2, as the doc already says (fg's `leg_headline` already knows
    `GATE INVALID`). Cost: +5 runs, absorbed by D4(a).
  - **(b) A bespoke blinding plant per gate**: unwrap tier-naming's and settle's wrappers for the test, disarm the
    capstone flag, hide the storage sorter. Each is the real blindness shape of its gate, but revisits keeps no
    reference to its originals (`__revisitWrapped = true`), so one gate would need (a) anyway: five couplings to
    prelude internals, and not uniform.
  - **(c) Out of scope**: file it to BACKLOG.

## §4 Units (gate each before the next; §6 protocol)

### Unit 0 — the rails (both repos)
1. **`Fizzygum-tests/scripts/run-all-headless.js`:**
   - `--tests=A,B` (in `KNOWN_FLAGS`). Each name must be a `tests/<name>/` directory, checked before any browser
     launches, or the run exits 2. To the loader a name is also a TAG (`selectTestsFromTagsOrTestNames`), and an empty
     selection is the whole manifest, so this check is what keeps a typo from running the suite. The probe's count
     must equal the number of names, or exit 2 naming the dropped ones (a pointer- or density-filtered test).
     `shardUrl` selects the named list instead of `['all']`. The banner says `SUBSET (n tests)`.
   - `PRELUDE_JS`, injected BEFORE `AUDIT_SRC`, with a `prelude: <path>` line. Update the runner's header and the
     tests repo's CLAUDE.md, whose PRELUDE_JS paragraph says the suite runners take it.
2. **`scripts/lib/audited-suite-with-infra-retry.sh`:** `run_audited_suite <prelude> <auditdir> <shards> <log> [runner
   args…]` passes the extra arguments on both attempts.
3. **The three shell gates:**
   - They parse `[shards] [--tests=A,B]` and refuse anything else (exit 2), passing `--tests` through.
   - The capstone's backfill loops over the subset when one is given.
   - The capstone's coverage shortfall becomes `CAPSTONE GATE INVALID`, exit 2 (D5).
4. **JS gates:** `revisit-gate.js` and `storage-invariant-gate.js` already pass `-- --tests=…` through; nothing changes
   beyond their headers' usage lines.
5. **`Fizzygum/buildSystem/run-selftests.js --headless`:** a pool of 3 (D4).
6. **The three static gates** take `--src=DIR` and refuse unknown arguments:
   - `census-public-private-calls.js`'s `runCensus` takes `{ src }`;
   - `check-page-loaded-elements.js`'s positional `[srcDir]` becomes `--src=`, one spelling for one rail.
7. **The proofs of Unit 0's own rails:**
   - `--tests=` with a non-test name exits 2 (seen);
   - `--tests=` with one name plays exactly one test (seen);
   - a gate given an unknown argument exits 2 (seen);
   - the existing gates still pass on the full suite (the gauntlet at the close).

### Unit A — the suite-gate bite-proofs (Fizzygum-tests)
- `scripts/lib/gate-bite-proof.js` is shared. It runs one gate command on `--tests=<T>` with an optional `PRELUDE_JS`
  plant, with `FIZZYGUM_KEEP_STALE_BROWSERS=1`. It returns `{ status, out, why }`, where `why` carries the exit, the
  signal and the last lines, as cache-oracle's `run` does.
- One `<gate>-selftest-headless.js` beside each gate. The cases are planted (exit 1 AND the rule's own report
  naming the plant, §5), blind (exit 2 AND the gate's INVALID line, D5) and control (exit 0 AND the gate's OK line).
  - `tier-naming-audit/tier-naming-gate-selftest-headless.js`
  - `notification-settle-audit/settle-gate-selftest-headless.js`
  - `revisit-gate-selftest-headless.js`
  - `storage-invariant-gate-selftest-headless.js`
  - `end-of-cycle-audit/capstone-gate-selftest-headless.js` (careless AND paint-time planted cases)
- The plants of §5, each in its gate's directory, and the shared blind plant.

### Unit B — the static-gate bite-proofs (Fizzygum)
- `buildSystem/lib/planted-src.js` copies `src/` into a fresh temp dir and adds or replaces named files.
- `buildSystem/check-call-separation-selftest.js`, `check-back-buffer-memos-selftest.js` and
  `check-page-loaded-elements-selftest.js` each run the real gate (child process, `--src=`) on:
  - the unplanted copy: exit 0;
  - each plant: exit 1, naming the plant's class and site or field;
  - each exempting variant: exit 0.
- The three headers' by-hand recipes become one line naming the self-test.

### Unit C — docs
- `lint-and-static-checks.md`:
  - a third rule beside "a SELF-TEST is a FILE" and "a SANCTION's guard must RUN": **a gate's RULE is proven to bite
    by a standing self-test that runs the gate** (the pattern, and why the gate rather than its prelude);
  - correct the coverage paragraph's "proven by plant" sentence (now true, and standing) and make "exits 2
    everywhere" true;
  - a row or pointer for each new self-test.
- The tier-naming gate's header (its "No standing self-test…" sentence).
- `Fizzygum-tests/CLAUDE.md`: the self-tests paragraph, the `PRELUDE_JS` paragraph, and the run-all-headless usage.
- The umbrella `CLAUDE.md`'s gauntlet blurb says what the `selftests` leg proves.
- BACKLOG: move the item into §9.

## §5 The plants (T = `SystemTest_macroAnalogClockInspectEdit`; each checks `currentlyPlayingTestName() === T` and keeps a counter)

| plant (file) | hook (order-independent) | act, bound | the planted case passes only on |
|---|---|---|---|
| tier-naming LEAF (`tier-naming-audit/leaf-react-plant.js`) | `Widget.prototype._assertBoundsWellFormed(where)`: it is called INSIDE each `__commit*` leaf (`@_assertBoundsWellFormed "__commitExtent"`), and the prelude does not wrap it | when `where` starts `__commit` and the receiver is the clock (`AnalogClockWdgt`), call `this._changed()`, a react step, inside the leaf's frame; 3 times | exit 1 and `leaf-fired-orchestration AnalogClockWdgt::__commit` |
| settle [J] (`notification-settle-audit/callback-flush-plant.js`) | `Widget.prototype._reactToBeingAdded`, wrapped to set a flag, plus `Widget.prototype._reLayoutSelf`, which the base callback calls (`_reactToBeingAdded: … @_reLayoutSelf()`), so the act happens inside the prelude's callback frame in either install order | when flagged, the clock, and `!world._recalculatingLayouts`, call `world.recalculateLayouts()`, a flush opened from a callback; once | exit 1 and `AnalogClockWdgt._reactToBeingAdded opened recalculateLayouts` |
| revisits (`audit-preludes/revisit-plant.js`) | `WorldWdgt.prototype._recalculateLayoutsBody`, inside the prelude's per-flush map and not wrapped by it | in the first flush with the clock attached, call `clock._reLayout()` twice before the body: two depth-0 entries; one flush | exit 1, `DRIFT SystemTest_macroAnalogClockInspectEdit`, `AnalogClockWdgt:` in `now` |
| storage (`audit-preludes/storage-plant.js`) | on the BOOT world, which T's opening `resetWorld` audits, once the boot world's own pending sort has drained (a drain would file the widget correctly, into the bin: measured, the boot world starts with a sort pending) | file one fresh unreachable widget onto `world.shelfWdgt` with no membership mark, so no drain runs and Tier A never sees it; once | exit 1 and `unstable-shelf-to-bin:Widget` |
| capstone careless (`end-of-cycle-audit/careless-push-plant.js`) | `WorldWdgt.prototype._runChildrensStepFunction`, a cycle station outside any settle | `clock._invalidateLayout()`, an off-settle push on an attached widget, undeclared; 3 cycles | exit 1, the careless report naming `AnalogClockWdgt`, and **0** paint-time schedules |
| capstone paint-time (`end-of-cycle-audit/paint-time-plant.js`) | `Widget.prototype.fullPaintIntoAreaOrBlitFromBackBuffer` while `world.healingRectanglesPhase` (last arc's plant, now confined to the clock and bounded) | `clock._invalidateLayout()` during paint; 3 frames | exit 1 and the PAINT report naming `AnalogClockWdgt` |
| blind, shared (`audit-preludes/unobserved-bucket-plant.js`) | `AutomatorPlayer.prototype.stopTestPlaying` | after T stops, print `LAYOUTAUDIT_TESTSTART SystemTest_BiteProofUnobservedBucket`; once | exit 2 and the gate's INVALID line (revisits and storage also name the bucket) |

Every plant is pixel-neutral by construction: it re-lays or re-damages a settled widget, so the geometry and the pixels
are unchanged, or it acts on the boot world, which T's reset dissolves. Any plant console.error opens with a token
(`PLANT_NOT_APPLIED: …`), because the fail-closed runners fail a test on an untokenised error line.

**Static plants (Unit B)**, each an ADDED class file in the copy:
- call-separation: `class BiteProofCallSeparationWdgt extends Widget` with a private method calling a public
  EFFECTFUL command of the chain, then the same with `# public-call-sanctioned: bite-proof fixture`. The callee is
  picked so the census classifies it EFFECTFUL, and the self-test asserts that classification first, so a drift there
  fails loudly instead of passing vacuously.
- back-buffer memos: a `_createRefreshOrGetBackBuffer` writing `@lastPaintedSize`, then the same field declared
  `# saved-content: …`.
- page-loaded elements:
  - `@img = new Image()` not transient;
  - transient but no `_reactToBeingCopied`;
  - an unattributed `new Image()`;
  - the fully-declared class (passes).

## §6 Cold-execution protocol and verification

0. `/Users/davidedellacasa/code/Fizzygum-all/fg status`: both repos clean at the SHAs §1 names (or at this arc's own
   commits). Read §1–§5. If D1–D5 are not recorded in §9, put them to the owner in ONE round first.
1. **Per unit:**
   1. Edit.
   2. Run the new proof directly. It must PASS on the real tree, and it must FAIL, each failure SEEN:
      - when its plant is neutralised (set the plant's bound to 0, and the planted case reports the gate passing);
      - when its control is broken (feed the control the plant, and the control case fails).
   3. `fg build`, then `fg presuite`.
2. **Shell rules:**
   - fg only by absolute path; never pipe a gating fg call.
   - Long ops run in the background, with an ETA and a status every ~5 min. A running fg op owns `src/`, `tests/`
     and `scripts/`, and `buildSystem/` while it builds.
   - Plants and probes live in `Fizzygum-tests/.scratch/` until promoted.
   - zsh: write a multi-line edit as `node - <<'EOF'`, and never `echo ====` (zsh expands `=word`).
   - `fg` is local: back it up to the scratchpad before editing it, and record its edits in §9.
3. **Close:**
   - `fg gauntlet` in the background (~16 min), and `cd Fizzygum-tests && npm run selftest`.
   - `fg homepage` only if `build_it_please.sh`, `src/boot` or `src/meta` changed (none is planned).
   - ONE independent end-of-arc review: a fresh agent given the goals and the diffs, not the ledger; read-only, no
     builds, fg or browsers.
   - Archive this plan (a plain `mv`: it is untracked), add an INDEX line, move the BACKLOG item into §9, update the
     memory note.
   - Draft the commit messages and WAIT for approval. Ask about push separately.

## §7 Risks

- **A plant that is not pixel-neutral, or that trips another gate token, fails the run for the wrong reason.**
  Examples: Tier A's `STORAGE_INVARIANT`, `WORLD_INVENTORY_*`, `DOWNWALK_UNREACHABLE_CHAINTOP`. The gate then stops
  at "embedded suite failed", before the rule's branch. The planted case requires the rule's own report, so this is
  loud, never a false pass; re-shape the plant.
- **A plant whose hook the test never reaches** (the clock never commits a `__commit*` in T, say) leaves the planted
  run green. That is loud too (the planted case fails); pick the receiver the test does reach.
- **Shared audit dirs.** A gate writes its fixed `.scratch/` dir, so a bite-proof run overwrites the last full run's
  forensics. The gauntlet never overlaps a gate's proof (wave A) with its full run (wave B). One file runs its own
  cases sequentially, so the pool never runs one gate twice at once.
- **Selecting by name loads every test's metadata** before selecting (`selectTestsFromTagsOrTestNames`), which may add
  ~1–2 s to a subset run against §2's manifest-edit figure. Measure in Unit 0.

## §8 Rejected alternatives (do not re-attempt)

- **A subset rail as an environment variable.** An export left in a shell would shrink every gate leg to a subset
  that passes. A flag cannot leak.
- **Composing plant and prelude into one file (cache-oracle's shape) for the gates.** The gate hard-codes its prelude
  path, so that would need a prelude override on every gate. `PRELUDE_JS` reaches all of them unchanged.
- **Unbounded or suite-wide plants** (gotcha (e), §3 D2).
- **Bite-proofs wired into fg's legs** (D4(c)): uncommitted tooling.
- **A meta-rule "every gate has a self-test".** The 33 static gates mostly have none, and that is an audit of its own,
  not this class (a rule proven by hand). It is a candidate BACKLOG item at the close.

## §9 Ledger

- 2026-11-07: plan authored. Survey and measurements as §1–§2. Probes: `Fizzygum-tests/.scratch/bite-proofs/`
  (`probe-callbacks.js`: which callbacks fire in T, and in what settle state).
- Owner decisions 2026-11-07, one round, all (a): D1 the real gate on a one-test subset; D3 the real static gate on a
  planted src copy; D4 one `selftests` leg, files 3 at a time; D5 coverage branches in scope with one shared plant.
- **Unit 0 (rails) — done 2026-11-07.**
  - `run-all-headless.js`:
    - `--tests=A,B` (names checked against `tests/` before any browser; the probe counts the selection, and a
      page-filtered name is refused);
    - `PRELUDE_JS`, injected ahead of `AUDIT_PRELUDE`;
    - `lib/shards.js`'s probe takes the selection.
  - `lib/audited-suite-with-infra-retry.sh` passes the runner arguments through, and gains `parse_gate_args`
    (`[shards] [--tests=A,B]`, anything else exits 2). The three shell gates source it FIRST, before the pkill. The
    capstone backfill runs over the subset; the capstone's armed shortfall is now `CAPSTONE GATE INVALID`, exit 2.
  - `run-selftests.js`: files run in a pool (node tier 4, headless tier 3, reports in discovery order; headless
    children get `FIZZYGUM_KEEP_STALE_BROWSERS=1`). The node tier is pooled as well as the headless one: the three
    static proofs took it from 1.9 s to 4.1 s sequentially, and pooled it is 1.7 s. Every node-tier fixture writes
    temp dirs or pid-tagged names of its own (checked).
  - `--src=DIR` on check-call-separation (`runCensus({ src })`), check-back-buffer-memos and check-page-loaded-elements
    (its positional `[srcDir]` retired); all three refuse unknown arguments.
  - Seen:
    - `--tests=SystemTest_NoSuchTest,shadow` exits 2 before any browser;
    - `--tests=<clock>` plays 1 test (7 s);
    - a mouse-only test under `--pointer=finger` is refused (the page keeps 1 of 2, exit 2);
    - each shell gate refuses `--self-test` (exit 2) and passes on `--tests=<clock>` in 7–8 s with no backfill;
    - the headless tier pooled runs in 49 s (68 s sequential), the node tier in 1.7 s.
- **Unit B (static proofs) — done 2026-11-07.** `buildSystem/lib/planted-src.js` and three node self-tests:
  - check-call-separation: 3 cases, 1.4 s. The plant is `BiteProofCallSeparationWdgt._bpPlantedPrivate -> @destroy`,
    which the census reads as SETTLING; the sanction marker passes it.
  - check-back-buffer-memos: 4 cases, 0.3 s. The memo fails; transient and saved-content both pass.
  - check-page-loaded-elements: 7 cases, 0.6 s. Not-transient, no copy hook, no restore hook and unattributed each
    fail on the intended clause (output read); declared and `page-element-not-held` pass.
  - Each SEEN failing with its plant neutralised (the field or the call no longer planted) and with its control fed
    the plant. The headers' by-hand recipes now point at the self-tests.
- **Unit A (suite-gate proofs), 2026-11-07.**
  - Files:
    - `scripts/lib/gate-bite-proof.js` (runGate on `--tests=<clock>`, `PRELUDE_JS` set or REMOVED from the env,
      `FIZZYGUM_KEEP_STALE_BROWSERS=1`);
    - the six rule plants of §5 and the shared `audit-preludes/unobserved-bucket-plant.js`;
    - five `*-gate-selftest-headless.js`.
  - Spike: every plant bites with the suite green (1 test, 0 failed, 0 gate-violations):
    - tier-naming: `leaf-fired-orchestration AnalogClockWdgt::__commitExtent`;
    - settle: 1 violation, `AnalogClockWdgt._reactToBeingAdded opened recalculateLayouts`;
    - revisits: `DRIFT …`, `now: ["AnalogClockWdgt:2"]`;
    - storage: `unstable-shelf-to-bin:Widget`;
    - careless: 3 careless, 0 paint-time;
    - paint-time: 3 careless and 3 paint-time.

    Every blind run exits 2 with the gate's INVALID line (`1/2` buckets).
  - ⭐ **The settle proof FOUND A DEFECT in the gate's own report.** `run-notification-settle-gate.sh`'s "by callback"
    summary used `sed 's/.*"callbackCtor":…,"opened":…".*"callback":…/'`, but the prelude emits `callback,
    callbackCtor, opened` in that order, so the sed never substituted and the summary printed the raw JSON line (twice,
    beside the raw section). It is fixed to the emitted order and seen printing
    `AnalogClockWdgt._reactToBeingAdded opened recalculateLayouts`. This is exactly the layer a prelude-only proof
    (D1(b)) would have left unproven.
  - ⭐ **The storage plant's first shape did NOT bite** (exit 0). Probed: the boot world starts with `sortPending`
    true, so its frame-1 drain filed the planted widget into the bin, correctly. The plant now acts only once nothing
    is pending; then it bites.
  - Whole headless tier, pooled: 8 self-tests, 45 cases, 74 s idle (it was 3 files in 68 s sequential).
  - SEEN failing, all five, through one driver (`Fizzygum-tests/.scratch/bite-proofs/neutralise.js`). It ran each
    proof with every plant neutralised (`WRONG_ACTS = 0`, the storage filing removed) and the control fed the
    blind plant. Every planted case FAILED (the gate exited 0), every control FAILED (the gate exited 2), and every
    blind case still passed: tier-naming 2/3, settle 2/3, revisits 2/3, storage 2/3, capstone 3/4.
  - Headers: each of the five gates names its proof, and the two JS gates' headers now state exit 2 = INVALID.
- **Gates, 2026-11-07:** `fg build` OK (node tier 25 self-tests, 1.9 s); `fg presuite` OK (177 s).
  - **Gauntlet #1: FAILED on `webkit` and `finger` (the two WebKit legs), 18/20.** It is MY regression:
    `lib/shards.js`'s probe passed `page.evaluate` TWO arguments `(pinGroup, wanted)`. Puppeteer accepts that,
    Playwright refuses it ("Too many arguments … wrap them in an object"), so both WebKit legs died at the probe in
    2 s, serial retries included.
  - Fixed: one object argument. Seen: `--browser=webkit --tests=<clock>` and the Chrome run both pass.
  - ⭐ Lesson: presuite is Chrome-only, so a change to a runner library BOTH drivers share needs a WebKit run before
    the gauntlet.
  - Every other leg passed. `selftests` ran 8 files, 45 cases, 126 s in-wave (wave A's longest suite leg, dpr2,
    took 192 s).
- **End-of-arc review (one fresh Opus agent, goals + diffs, read-only): 20 findings; all verified against the code.**
  - **R1 HIGH:** the WebKit probe (`evaluate` with two arguments). Already fixed above.
  - **R2 HIGH (contingent):** a bite-proof wrote the SAME fixed audit dir and suite log as its gate's own leg, and a
    timeout killed a process, not the tree under it. An orphaned bite-proof could therefore empty a real leg's dir
    mid-run, and four gates count only the logs present, so the leg would pass a partial audit.
    - Fixed: every gate takes `--out=DIR` (`parse_gate_args` for the shell gates, the JS gates' own flag), and
      `gate-bite-proof.js` gives every run a fresh temp dir, removed after it.
    - `run-selftests.js` kills a timed-out file's whole process TREE (`processTree` via ps), seen killing a bash
      and its two grandchildren.
  - **R3 MED, vacuous checks:** page-loaded-elements' three naming checks matched words the gate's summary always
    prints. Now each matches its own violation line (`^  <Class>.<field>  (<file>:<n>) — <clause>`). Seen: each
    clause's output fails the others' checks. back-buffer-memos is anchored the same way.
  - **R4 MED:** a failing static control showed the advice footer, not the offender. `planted-src.js`'s `why`
    now carries the gate's failure lines (seen naming the field and line).
  - **R5 MED, vacuous blind case:** the capstone's blind case could not see either flag's coverage condition alone.
    The shared blind plant takes the lines its bucket DOES hold (`unobservedBucket(lines)`), and the capstone runs
    one bucket armed for the careless flag only and one armed for paint only, each required to read INVALID on the
    other.
  - **R6 MED:** a stray exported `PRELUDE_JS` would now plant every suite leg. `run-all-headless.js` honours it
    only beside `--tests` and refuses it otherwise (exit 2, seen). A whole-suite instrument rides `AUDIT_PRELUDE`.
  - **R7:** an empty `--tests=` made the capstone backfill the whole suite. `parse_gate_args` refuses an empty
    `--tests=` or `--out=` (seen under bash 3.2), and the backfill runs only after a suite run that passed.
  - **R8:** a bare `--tests` ran the whole suite. It is refused (seen).
  - **R9:** the pool could hang on a failed spawn, and the per-file limit equalled fg's leg alarm.
    - A spawn `error` with no pid now settles the file.
    - An exit guard makes a run that never reached its verdict exit 2.
    - The headless per-file limit is 480 s, under the leg's 600 s.
  - **R10 (latent):** a subset revisit run compared against the whole-suite baseline. It now compares only its own
    tests' entries, and `--write-baseline` with `--tests` is refused (seen).
  - **R11:** check-call-separation now refuses a positional argument too (seen).
  - **R12:** name validation counted files (`testsManifest.js` passed). It now counts directories only (seen).
    The probe returns names (`probeTestsOrExit`), so a page-dropped test is named.
  - **R13–R17 (docs):** churn-set's `PRELUDE_JS` note; the tests repo's CLAUDE.md (where standing plants live, the
    capstone's extra cases, order-independence rather than injection order); the checks index's "Two rules read it"
    (the bite rule is now its own paragraph); the gates' exit lists; past-tense narration in `gate-bite-proof.js`.
  - **R18:** fg's comments said the selftests leg ran one file at a time; they now describe the pool (fg is LOCAL
    and its backup is `scratchpad/fg.before-bite-proofs`). The BACKLOG move happens at archive.
  - **R19:** a plant whose hook vanished polled forever, and its case read as a plain GATE PASSED. Every plant now
    reports `PLANT_NOT_APPLIED: <file>` once it is still unapplied 60 frames after the world appears.
    - The first cut counted 1200 frames from page load, which a 5 s one-test run never reaches; caught before
      running.
    - Seen: a plant hooking a missing method fails its case with that line first in the detail.
  - **R20:** `planted-src` copies leaked on SIGKILL or Ctrl-C. Each new copy now sweeps `planted-src-*` dirs older
    than an hour.
- **After the fixes:** the node tier passes (25 self-tests, 1.8 s). The neutralisation driver, rerun, gives every
  planted case and control FAILED and every blind case passing: capstone 3/5 now, the two one-flag blind cases passing.
  - The real-tree headless tier passed 7/8. The capstone proof's CONTROL failed once: its embedded runner threw
    before playing anything (exit 1, no RESULT block, 0 logs), so the gate read INVALID. It did not reproduce: 3 runs
    alone, 3 passes.
  - Placed: a throw outside the shards (a shard's errors are caught and banked) is the shard-count probe, which
    retried a page that was not ready but not a launch or navigation that THREW. That gap predates this arc, but the
    proofs launch it ~17 more times a gauntlet.
  - Fixed: `probeTestsOrExit` retries a thrown probe once in a fresh browser. Seen with a fake page factory: one throw
    is retried, two throw. `gate-bite-proof.js`'s `why` now carries the first error line ahead of the tail, so the
    next flake names itself.
- **Close, 2026-11-07:**
  - `fg presuite` OK (177 s).
  - **`fg gauntlet` 20/20, no retries, 918 s.** `selftests` ran 8 files, 46 cases, in 146 s in-wave, inside wave A's
    longest suite leg (dpr2, 211 s).
  - `npm run selftest` OK (12 self-tests, 217 cases); the build's node tier: 25 self-tests, 1.8 s.
  - `fg homepage` not run: neither `build_it_please.sh` nor `src/boot` or `src/meta` changed.
  - fg (local, no repo) edits: the two `selftests` comments only (backup `scratchpad/fg.before-bite-proofs`).
  - The BACKLOG item "Standing bite-proofs for the checks proven only by hand" is closed into this ledger.

## References
- `docs/archive/unrun-checks-plan.md` (prior arc, its ledger, gotchas (a)–(f)).
- `docs/architecture/lint-and-static-checks.md` §3 (every check runs) and the runtime audit gates section.
- `Fizzygum-tests/CLAUDE.md` (the `PRELUDE_JS` plant rail; the self-tests paragraph).
- Memory: `unrun-checks.md`.

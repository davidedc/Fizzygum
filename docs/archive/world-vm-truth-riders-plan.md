# VM-truth riders — Arc B of the object-lifetime program

**STATUS: EXECUTED IN FULL + ARCHIVED 2026-08-20 (authored and executed the same day).**
All phases done; closing `fg gauntlet` GREEN **18/18** (the new `vmtruth` wave-C leg PASSED
its first gauntlet at 93 s; `refs` was the known benign serial-retry load flake), 7m23s
total; zero recaptures across the arc. §5's S0–S3 blocks and §D5's results block are the
execution ledger — every measured number lives there. Landed: the `AUDIT_CHROME_ARGS`
launch-args seam; `audit-preludes/vm-truth-prelude.js` (WeakRef collectibility oracle at
one-teardown grace + post-GC heap samples); `vm-truth-gate.js` (`fg vmtruth`, three
verdicts, INVALID-on-unmeasured); `heap-forensics.js` (four lenses + `--selftest`,
absorbing the retired `.scratch/inventory-detach-test-forensics.js` — the promotion rider);
the D6 door-callback law (five guarded funnel tails + the `PartsRegistry` header doctrine)
with its D6b destroy-mid-load race gate in the `parts` leg. All three D5 plants proven then
removed. The named `FinalizationRegistry` oracle was ABSORBED by the WeakRef sweep (§8).
Living truth: `../architecture/world-lifetime-and-inventory.md` §6.

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-20. All `file:line` refs verified against that day's heads (Fizzygum `791cdc90`,
tests `8c413d3ca`); **line numbers drift — the method/symbol name is the authoritative anchor,
re-grep it before trusting a number.**

**Mandate.** Give the object-lifetime program the one witness it still lacks: the VM itself.
Arc A's in-band gate walks properties — it structurally cannot see a widget pinned by a CLOSURE,
a listener, a promise reaction, or any reference that lives only in the engine's heap. This arc
adds a Chrome-only measurement tier that asks V8 directly ("is this destroyed widget still
alive after a forced GC? is the page's post-GC heap flat across the suite? what retains this
object?") — as standing GATES where the answer is cheap, and as an on-demand FORENSIC tool
where it is not. The standard is the same as Arc A's: one coherent instrument with declared
exemptions and a prove-it-fails obligation, not a pile of ad-hoc probes.

---

## §0 Orientation

**Framework context.** Fizzygum is a CoffeeScript GUI framework rendered on one canvas; no
module system — every class is a global on `window`; the SystemTest suite (sibling
`Fizzygum-tests` repo; `fg status` prints the live count, 307 today) runs all tests in ONE page
per shard, `world.resetWorld()` being every test's first command.

**The program this plan belongs to** (decided 2026-08-20 with the owner; Arc A's plan —
`docs/archive/world-inventory-instruments-plan.md` §0 — states it in full):

- **Arc A (DONE, archived)** — the in-band `WorldInventory` gate at every suite teardown, both
  engines: identity-level escaped/zombie widget diffs, declared page-lifetime stores, statics/
  DOM/module-state drift. It found seven product leak mechanisms including the unbounded-LRU
  corruption. Doctrine + failure-reading guide: `docs/architecture/world-lifetime-and-inventory.md`.
- **Arc B (THIS PLAN)** — Chrome-only VM-truth riders: a forced-GC collectibility oracle and
  heap-slope gate over the full suite, a `queryObjects` cross-check against the in-band
  registry, and a heap-snapshot forensic tool with retainer paths. Named target: lazy-part
  promise tails (`world.parts.ensureLoaded(...).then => @…`) running on / pinning destroyed
  widgets. Rider: promote the gitignored probe `.scratch/inventory-detach-test-forensics.js`
  into a real `scripts/` tool.
- **Arc C (FUTURE)** — reset-by-reconstruction: `resetWorld` becomes destroy + `new WorldWdgt`,
  and the reset invariant collapses to "WeakRef to the old world + forced GC ⇒ collected".
  Sized by what A and B find. **Arc B builds exactly the oracle Arc C's invariant needs** —
  that WeakRef-plus-forced-GC machinery is this plan's D2, aimed today at destroyed widgets
  and tomorrow at the whole world object.

**Critical reframe (do not lose this):** the in-band walker deliberately COUNTS functions and
never walks them (`WorldInventory` traversal rules, Arc A plan §D1) — so a closure that
captures a widget is invisible to it BY DESIGN, not by omission. That is the entire seam this
arc fills, and it is why D5's plant-a-leak proof plants a CLOSURE: the same plant must leave
the Arc A gate SILENT and fail the Arc B gate, or the arc has not added what it claims.

**Why Chrome-only is BY DESIGN, not a gap.** Forced GC, `Runtime.queryObjects`, and heap
snapshots are V8/CDP capabilities; WebKit's Playwright driver has no equivalent rail. Arc A's
in-band gate — plain in-page JS — already runs identically on the webkit suite leg, so
cross-engine lifetime coverage exists; this arc ADDS depth on one engine rather than breadth.
Nothing in this arc may degrade the webkit path: the new machinery is env-gated into
Chrome-only runs and refuses loudly (never silently no-ops) if pointed at webkit.

## §0.5 Cold-execution protocol

1. Run `/Users/davidedellacasa/code/Fizzygum-all/fg status` (NEVER `./fg`; absolute path
   always). Expect all repos clean or explainably dirty, build FRESH or rebuild.
2. Read this plan fully, then `docs/architecture/world-lifetime-and-inventory.md` (what the
   in-band tier already gates — this arc must ADD, not duplicate). Re-grep every symbol you
   are about to touch (§1 lists them).
3. Execute phases IN ORDER (§6). Phase 1 is scratch-only; 2–5 touch tests-repo scripts (and
   Fizzygum src only for repairs) and each ends at a named gate. Iterate with `fg presuite`
   where product code changed; the new gate self-verifies; close the arc with the full
   gauntlet.
4. Long ops: launch ONCE in background redirecting to a log; peek `/tmp/fg-<cmd>.verdict` at a
   ~5-min cadence. Never pipe a gating fg call through `tail`/`grep`. A running op OWNS
   src/tests — edit only docs/memory while one runs.
5. Ad-hoc Node probes go under `Fizzygum-tests/.scratch/` (gitignored) — NOT the session
   scratchpad (`require()` resolves from the script's dir).
6. Owner rules: never commit/push autonomously — propose message(s) via `git commit -F` and
   wait. No conclusions before evidence (never write "collects"/"flat slope" before the run).
   Plans/docs stay present-tense.

## §1 Current state (the machinery this plan builds on) — verified 2026-08-20

**The teardown seam and its gates.** `WorldWdgt.resetWorld` (harness-side,
`Fizzygum-tests/Automator-and-test-harness-src/WorldTestSupport.coffee`) runs the teardown and
then, synchronously before returning, the two standing audits: the world-field ratchet
(`RESETWORLD_INCOMPLETE`) and the object-lifetime inventory
(`_auditWorldInventoryNoSettle`, emitting `WORLD_INVENTORY_DRIFT/_ESCAPED/_ZOMBIE`). So a hook
that wraps `resetWorld` and acts AFTER the original returns lands after teardown + audits —
the exact moment "everything destroyed should now be collectible" becomes assertable.

**The identity registry.** `Widget.registerThisInstance`
(`src/basic-widgets/Widget.coffee` ~:447) adds every widget to its whole superclass chain's
`instances` Sets; `unregisterThisInstance` (~:458) removes it, called ONLY from
`_destroyNoSettle` (~:693). Registration is COMPLETE across all instantiation paths: the
meta-compiler injects `registerThisInstance?()` into every constructor
(`src/meta/Class.coffee` ~:60, ~:348), and both `Object.create` shells call it explicitly —
`Deserializer` (~:88) and `Duplicator._cloneContentInto` (~:178). Consequence: after a full
GC, `queryObjects(Widget.prototype).length − Widget.instances.size` = widgets the VM retains
that the registry says are gone (destroyed-but-uncollected) — and a NEGATIVE-side mismatch
(alive object not in the registry) would be a registration hole. That identity is the D4
cross-check.

**The audit-prelude rail** (the sanctioned injection seam, used by the `storage` and
`revisits` gauntlet legs): `run-all-headless.js` (~:78) env-reads `AUDIT_PRELUDE` (a JS file
injected into every shard page via `addInitScript`, persisting across stall-recovery reloads)
and `AUDIT_DIR`; console lines starting `LAYOUTAUDIT` are bucketed per test into
`<AUDIT_DIR>/<test>.log`, keyed on `LAYOUTAUDIT_TESTSTART <name>` markers (~:164–179);
`AUDIT_ECHO=1` relays them live. A prelude installs by rAF-polling for the world, wraps
`WorldWdgt.prototype.resetWorld`, and announces itself once
(`scripts/audit-preludes/storage-audit-prelude.js` is the template — including its
attribution nuance: at the reset seam the current test name is already the INCOMING test, so
a finding describes the PREVIOUS test's residue, and the LAST test of a shard is never
audited by the prelude). The wrapper-script shape is `scripts/storage-invariant-gate.js`:
spawn `run-all-headless.js` with the env set, then post-process `AUDIT_DIR` and exit 0/1.

**What the runner does NOT yet have.** (a) No way to pass extra Chrome launch args —
`launchChrome` (`scripts/lib/headless-driver.js` ~:61) hard-codes
`['--allow-file-access-from-files', '--no-sandbox']`; forced GC needs
`--js-flags=--expose-gc` (D1 adds the seam). (b) No runner-side page handle for outsiders —
`run-all-headless.js` owns its browsers, so anything CDP-only (queryObjects, snapshots)
cannot ride the suite runner and lives in the dedicated tool (D4) instead. (c) No per-test
runner-side callback (1 Hz polling only) — which is why ALL per-teardown work in this arc is
in-page (the prelude), never runner-driven.

**The gate-token list** (`scripts/lib/gate-tokens.js`) is consumed by run-all + run-macro +
run-sequence. This arc adds NO token to it: like the storage Tier-B gate, the prelude's
findings travel as `LAYOUTAUDIT`-prefixed lines that only exist when the prelude is injected,
and the wrapper script is the gate. (A token would be dead weight in every normal run.)

**The lazy-part door funnels** (`src/PartsRegistry.coffee`): `ensureLoaded` (~:109, memoized,
promise per part), `whenAllLoaded` (~:150 — SYNCHRONOUS fast path when parts are already in;
that fast path is a correctness requirement, see its comment), `whenOptionalPartsLoaded`
(~:174), `whenClassAvailable` (~:202), `launch` (~:181). Callback-capturing call sites in
src: `Widget.editLayout`'s bare tail `ensureLoaded('authoring').then => @showAdders(…)`
(`Widget.coffee` ~:5575), `WorldWdgt` snapshot pre-scan `ensureAllLoaded(missing).then =>`
(~:2561), `WindowedApp` (~:73–74), `Widget` meta-tools doors (~:4400, ~:4410),
`WidgetFactory` (4 sites), `DemoMenus` (`launch` ~:54 + 7 `whenAllLoaded` sites),
`ExamplesFolderWindowWdgt` (~:58), `AppLauncherWdgt` (~:113), `WorldWdgt` demos doors
(~:2923, ~:2947). ⚠ **The harness page presets `FIZZYGUM_EAGER_ALL_PARTS`** (PartsRegistry
header comment ~:22), so on the SUITE page every funnel runs its callback synchronously and
NO pending promise tail ever exists — the named-target retention class is only real on
`index.html` (the dev build's lazily-parted page, the one the `parts` gauntlet leg drives).
S3 therefore probes `index.html`, not the harness.

**Expectations the spikes must verify (stated as expectations, NOT facts):** the eight LRU
caches key on STRINGS (e.g. `PaletteAppearance` header: "keys the buffer on class…"; the
text caches key on text/style strings), so they should pin canvases but not widget objects —
destroyed-widget collectibility after GC may already be near-crisp on a green suite. The
harness page's post-GC heap size and its across-suite series are UNMEASURED. Snapshot size
for the booted harness page is UNMEASURED (heap snapshots run 1–2× heap size; Node's
~512 MB max-string makes whole-doc `JSON.parse` a real risk — D4's parser reads the file
incrementally).

**Tooling facts:** Puppeteer `^22` / Playwright `^1.40` (tests `package.json`).
`WeakRef`/`FinalizationRegistry` exist in both engines but forced GC exists only on Chrome.
Whether Puppeteer 22 still ships `page.queryObjects` (deprecated upstream at some point) vs.
raw CDP `Runtime.queryObjects` via `page.createCDPSession()` is S0's question — the tool
gets one spelling, chosen by the spike.

## §2 Why it is shaped this way

Arc A deliberately deferred everything needing the VM (its §8: "CDP-based per-test accounting
— no per-test callback exists runner-side; Chrome-only, so the webkit leg goes blind.
Deferred to Arc B as riders, by design." and "`WeakRef`/`FinalizationRegistry` in this arc —
meaningless without forced GC; that is Arc B."). The deferral bought Arc A both-engine
coverage and an instrument with zero runner coupling; the price was a stated blind spot —
closure-held retention — which this arc now pays for with the tier that can see it. The
prelude rail (not a runner rewrite) is the shape because it already exists, already survives
stall-recovery reloads, and already has two shipped gates proving the pattern
(`storage`, `revisits`).

## §3 The distilled argument

- **The seam is free.** resetWorld-wrap preludes, AUDIT_DIR bucketing, the wrapper-gate
  shape, fg legs — all shipped and battle-tested. The new engineering is ~150 lines of
  prelude, a wrapper, one launch-args seam, and the forensic tool.
- **The oracle is synchronous.** A `WeakRef.deref()` after a forced major GC answers
  "collectible?" deterministically, with identity (`<Class>#<id>`), at ~tens of ms per
  teardown. (A `FinalizationRegistry` answers the same question via callbacks whose timing is
  unspecified even after GC — see §8.)
- **Slope closes the aggregate hole.** Identity oracles see widgets; they cannot see a
  closure accumulating strings, detached DOM, or render surfaces. One post-GC heap number per
  teardown, gated per page across ~40 teardowns, catches ANY unbounded accumulation
  regardless of type — the exact class the in-band gate demoted to report-only.
- **Arc C needs this instrument.** Its acceptance invariant ("old world WeakRef + forced GC
  ⇒ collected") IS this arc's D2 pointed at one object. Building and hardening the oracle
  now, against 307 real tests, is the de-risking step for the program's endgame.
- **The named target is a real user race.** On `index.html` a user can destroy a widget (close
  its window) while the part its door requested is still loading; the tail then runs
  `@showAdders(…)` on a destroyed widget. The suite structurally cannot see this (eager
  parts); only S3's probe can.

## §4 Deliverables (design decided; executor implements, does not re-litigate)

### D1 — the extra-Chrome-args seam
`scripts/lib/headless-driver.js`: `launchDriver`/`launchChrome` accept `extraChromeArgs`
(array, appended to the fixed args). `scripts/run-all-headless.js`: env
`AUDIT_CHROME_ARGS` (space-separated; env-gated like `AUDIT_PRELUDE`, invisible unset)
threads it through — and **refuses loudly (exit 2) when combined with `--browser=webkit`**
(a silently ignored dose is the atlas-fuzz false-coverage trap). Also honored by
`run-macro-test-headless.js` if trivial (same env read), else documented as run-all-only.

### D2 — `scripts/audit-preludes/vm-truth-prelude.js` (the in-page oracle)
Template: `storage-audit-prelude.js` (rAF install poll, resetWorld wrap, TESTSTART protocol,
announce line). Two wraps:

- **`Widget.prototype.unregisterThisInstance`** — on each call, record
  `{ref: new WeakRef(this), name: ctor.name + '#' + instanceNumericID, batch, test}` into a
  tracked list. (Unregister is the moment a widget leaves the live registry — from then on it
  is supposed to be garbage.)
- **`WorldWdgt.prototype.resetWorld`** — AFTER the original returns (teardown + Arc A audits
  done): increment the batch counter; force GC (`window.gc()` twice, or the S0-chosen
  spelling); prune tracked entries whose deref is gone; for entries **at least one full
  teardown old** (batch < current − 1 — the grace period keeps per-cycle transients out of
  the verdict; S1 may tighten it to the current batch if the evidence says zero noise), any
  still-alive deref is a finding:
  `LAYOUTAUDIT VMTRUTH uncollected:<Class>#<id> destroyedDuring:<test>`;
  then one sample line: `LAYOUTAUDIT VMHEAP page:<pageId> seq:<n> bytes:<usedJSHeapSize>`
  (post-GC `performance.memory.usedJSHeapSize`; `pageId` minted once per page load so the
  wrapper can reconstruct per-page series across stall-recovery reloads).

If `window.gc` is missing the prelude announces `gc=0` and emits NO samples — the wrapper
then reports INVALID (self-proving measurement, the fg-fuzz lesson: a gate that measured
nothing must not read as green). Overhead budget: WeakRef creation is O(destroys), the sweep
is O(tracked survivors); the GC pause is the real cost — S1 measures it.

### D3 — `scripts/vm-truth-gate.js` (the gate; the new fg leg)
Shape: `storage-invariant-gate.js` verbatim — spawn `run-all-headless.js` with
`AUDIT_PRELUDE`/`AUDIT_DIR`/`AUDIT_CHROME_ARGS=--js-flags=--expose-gc`, chrome-only
(hard-refuse a `--browser=webkit` pass-through), `--audit-dir=DIR` re-check mode, extra
flags after `--` passed through. Post-processing, in order:

1. **INVALID guard (exit 2):** every `<test>.log` in AUDIT_DIR must contain ≥1
   `LAYOUTAUDIT VMHEAP` line (each test's opening reset emits one; a missing sample means
   the prelude did not install or GC was unavailable — the run measured nothing). The known
   holes are stated, not silent: the last test of each page has no closing reset (same limit
   as the storage gate), and a stall-skipped test may lack a bucket.
2. **Collectibility findings (exit 1):** any `LAYOUTAUDIT VMTRUTH uncollected:` line, minus
   declared exemptions. The exemption table starts EMPTY and lives in the gate script with
   per-entry reasons (Arc A's D6 discipline); S1 decides whether any entry is honest
   (expectation: none — string-keyed caches should not pin widgets).
3. **Heap-slope gate (exit 1):** group VMHEAP samples by `page:`, order by `seq:`; per page
   with ≥ N samples, compare a robust tail statistic to a robust post-warm-up head statistic
   (candidate: median of last 5 vs median of samples 5–10, threshold in MB). **The statistic
   and threshold are S1's deliverable, recorded here when measured** — do not gate on a
   guessed number (the 1469-storm lesson wears a new coat here: JIT warm-up, atlas growth,
   and LRU fill are legitimate early growth).
4. Verdict lines: `vm-truth-gate: OK …` / `FAILED …` / `INVALID …` (exit 0/1/2), with the
   fuzz-style rule printed in the header: INVALID is never a pass.

fg integration (LOCAL umbrella file, uncommitted): a `vmtruth` leg in the gauntlet's wave B —
five mechanical edits mirroring `storage`: the `run_leg` case (`to 900`,
`--shards="${FG_GATE_SHARDS:-6}"`), `leg_headline` pattern (`vm-truth-gate: (OK|FAILED|INVALID)`),
the standalone `fg vmtruth` subcommand, the usage text, and the two leg lists
(`legs_pending`, wave-B `run_wave`). Presuite is deliberately NOT extended (inner loop stays
lean; this is a commit-point gate).

### D4 — `scripts/heap-forensics.js` (the on-demand forensic tool; absorbs the rider)
One tool, four lenses, run against the built harness page (own browser, chrome-only,
launched with `--js-flags=--expose-gc`):

- `--test=SystemTest_X` / `--tests=A,B,…` / `--boot-only`: boot, run the named test(s) the
  way the promoted probe does (select + play + poll idle), then a revealing `resetWorld()`.
- **Lens 1 — in-band anatomy** (the promoted
  `.scratch/inventory-detach-test-forensics.js`, which this tool REPLACES): relay
  `WORLD_INVENTORY_*` lines; for every live-but-unreachable widget print class, id, text
  extract, and the `parent` chain.
- **Lens 2 — collectibility:** forced GC, then sweep `Widget.instances` and a
  destroyed-widget WeakRef list (tracked from a small in-page wrap installed at boot) —
  print every destroyed-but-alive identity.
- **Lens 3 — the registry cross-check:** `queryObjects(Widget.prototype)` (S0's spelling:
  Puppeteer's `page.queryObjects` or raw CDP `Runtime.queryObjects`), map the returned
  handles to `<Class>#<id> destroyed:<bool>` in-page, diff against `Widget.instances` both
  ways: VM-alive ∖ registry = retained corpses (with names); registry ∖ VM-alive is
  impossible and printed as a registration bug if ever non-empty.
- **Lens 4 (`--snapshot`) — retainer paths:** CDP
  `HeapProfiler.takeHeapSnapshot` streamed to a file in `.scratch/`; a dependency-free
  parser — plain whole-doc `JSON.parse` behind a size guard (S0 measured the booted world's
  snapshot at 24 MB; cap ~300 MB → bail with a message rather than OOM); build the
  reverse-edge index for the suspect node(s) (filter: constructor-name = a Fizzygum widget
  class, or `--grep=<Class>`); BFS toward GC roots; print the shortest retainer path with
  edge names — the closure-variable names V8 records are exactly what the in-band gate
  cannot produce.

After D4 lands, delete `.scratch/inventory-detach-test-forensics.js` (gitignored; nothing to
commit — note the promotion in the tool's header provenance comment).

### D5 — prove the gates FAIL (mandatory, per standing case law)
Three plants, each removed after its proof run:
1. **Closure plant (the arc's thesis proof):** a harness-side statement making some class
   static hold `-> thePlantedWidget` (a FUNCTION capturing a widget a test created and
   destroyed). Run BOTH tiers over a suite segment: the Arc A in-band gate must stay
   SILENT (functions are counted, never walked — if it fires, this plan's premise is wrong;
   stop and re-frame), and `vm-truth-gate` must emit the
   `VMTRUTH uncollected:<Class>#<id>` identity.
2. **Slope plant:** a prelude-side (or planted-static) per-teardown accumulation of ~1 MB
   strings; the slope gate must fail.
3. **INVALID plant:** run the wrapper once WITHOUT the expose-gc arg (or with the announce
   suppressed); it must exit 2, not 0.

**D5 RESULTS (2026-08-20):**
- **Plant 3 PROVEN first (cheapest):** the suite run without the expose-gc dose printed
  `ALL TESTS PASSED` — exactly the trap — every shard announced `gc=0`, zero buckets were
  written, and the gate said `INVALID` exit 2.
- **Plant 1 PROVEN (in product code — `unregisterThisInstance` traps the first
  `instanceNumericID == 5` widget per page in a function-valued static closure):** the
  suite itself stayed GREEN (the in-band gate silent on the closure — the premise holds at
  suite scale), and `vm-truth-gate` FAILED exit 1 with **2579 uncollected findings**: one
  trapped widget per page (e.g. `ToolTipWdgt#5`) plus its transitively pinned destroyed
  cohort (`TextWdgt#34`, `MenuHeader#1`, …), each named with its `destroyedDuring` test and
  re-reported at every later sweep. Retention is transitive and the gate shows the whole
  pinned subtree — better forensics than the plant asked for.
- **Plant 2 first dose UNDER-POWERED — a lesson recorded:** `new Array(500000).fill "d5"`
  (~4 MB of pointers/teardown on paper) moved the floors to +60…94 MB — visibly above the
  green baseline (+11…44 MB) yet under the 96 MB limit (V8 stores a filled-with-one-value
  array cheaply). The proof dose is 200 000 UNIQUE strings per teardown
  (`("d5-" + i for i in [0...200000])`) — real, non-poolable payload. **Plant 2 PROVEN
  with that dose:** all 8 pages FAILED the floor gate (growth +133.5…178.0 MB against the
  96 MB limit), gate exit 1. Both plants then removed (git checkout of the two files).
- **The tool's plant proof is PERMANENT:** `heap-forensics.js --selftest` plants a
  closure-held destroyed widget on every invocation and requires lens 2 + lens 3 to name
  it, lens 4's path to name the plant property (`__heapForensicsSelftestPlant` via
  `context:w`), and the in-band gate to stay silent on it — proven green.

### D6 — the named-target probe and its repairs
S3 (below) drives the `index.html` promise-tail race. IF it demonstrates the correctness bug
(tail runs on a destroyed widget) or a retention worth fixing, repair at the honest layer —
the decided shape is a **funnel-level guard, not per-site patches**: the widget-capturing
doors go through one helper that no-ops when its subject widget is destroyed at resolution
(candidate spelling: `whenAllLoadedFor(widget, partNames, thenDo)` beside `whenAllLoaded`,
or a documented `return if @destroyed` FIRST LINE convention in every tail — pick whichever
the sites support with less churn, and gate-proof it: the existing `check-part-edges.js` and
call-separation gates police the new member's placement). Repairs ride `fg presuite` + the
`parts` gauntlet leg (the only leg that drives `index.html` laziness).

**D6b — the race gets a durable gate:** fold the S3 scenario into
`Fizzygum-tests/scripts/parts-lazy-load-headless.js` (the `parts` leg rig that already
drives a real lazy load on `index.html`): fire a widget-capturing door, destroy the widget
mid-load, and after the part arrives assert the corpse gained no children, no console
error fired, and the widget collects under forced GC (launch the rig's browser with the
expose-gc flag; skip the GC half gracefully if `window.gc` is absent so the rig stays
runnable in odd environments — but assert the corpse-mutation half unconditionally).

### D7 — docs + program bookkeeping
- `docs/architecture/world-lifetime-and-inventory.md`: §5 grows the VM-truth tier — what the
  gate asserts, how to read `VMTRUTH uncollected` / slope / INVALID, the attribution nuance
  (same PREVIOUS-test semantics as every reset-seam gate), and the forensic tool's four
  lenses.
- Root `CLAUDE.md` gauntlet paragraph + `Fizzygum-tests/CLAUDE.md` maintenance-scripts list:
  one sentence each for the new leg + tool (leg count 16 → 17 where stated).
- `docs/BACKLOG.md`: close the Arc B pointer; Arc C pointer gains "oracle ready (Arc B D2)".
- Close ritual on arc completion: `git mv` this plan to `docs/archive/`, STATUS stamp,
  `archive/INDEX.md` line, memory topic update.

## §5 Spikes (Phase 1 — scratch only, no src/scripts edits)

- **S0 — capability probe** (`Fizzygum-tests/.scratch/vmtruth-capability-probe.js`): on THIS
  Puppeteer/Chromium: (a) `--js-flags=--expose-gc` under `headless:'new'` → `window.gc`
  exists; pick the gc spelling (bare `gc()` ×2 vs `gc({type:'major'})`) by measuring when a
  freshly dereferenced object's WeakRef clears; (b) `page.queryObjects` present? else CDP
  `Runtime.queryObjects` via `page.createCDPSession()` — record the working spelling;
  (c) `HeapProfiler.takeHeapSnapshot` on the BOOTED harness page: wall time, snapshot bytes,
  post-GC `usedJSHeapSize` (decides D4's parser constraints); (d) GC pause duration on that
  heap (decides D2's overhead budget). Deliverables: numbers + chosen spellings RECORDED IN
  THIS DOC.

  **S0 RESULTS (2026-08-20, Puppeteer 22.15.0):**
  - `--js-flags=--expose-gc` works under `headless:'new'`; bare `gc()` ×2 is the spelling
    (the options form `gc({type:'major',execution:'sync'})` is also accepted).
    ⚠ **The WeakRef same-turn law, measured:** a WeakRef created (or deref'd) in the current
    JS job keeps its target till end of turn — a same-`evaluate` create→gc→deref NEVER
    clears. Create refs in one turn, sweep in a later one (the reset-seam design already
    does). A destroyed widget whose ref was taken in an earlier turn collects cleanly.
  - Booted harness world: post-GC `usedJSHeapSize` ≈ 51 MB; the double-gc pause is ~12 ms —
    per-teardown cost is negligible, D3 keeps full every-teardown frequency.
  - `page.queryObjects` EXISTS and works on Puppeteer 22.15. ⚠ It returns every object with
    `Widget.prototype` in its CHAIN — which includes all ~258 subclass PROTOTYPE objects
    (measured: 270 hits vs `Widget.instances.size` = 12 on a pristine world). The D4
    cross-check must filter to instances: own-property `instanceNumericID` (assigned per
    instance at construction; prototypes carry none).
  - Heap snapshot of the booted world: **24.2 MB in 0.3 s** — far below Node's string
    limits, so D4's parser is a plain whole-doc `JSON.parse` behind a size guard (~300 MB
    cap → bail with a message); the incremental-scan design is NOT needed at these sizes.
  - `performance.memory.usedJSHeapSize` is QUANTIZED by default (identical 56 800 000 across
    four sweeps) — useless for a slope. **`--enable-precise-memory-info` un-quantizes it**
    (verified: distinct byte-accurate values), so the gate's dose is BOTH flags:
    `AUDIT_CHROME_ARGS="--js-flags=--expose-gc --enable-precise-memory-info"`.
  - 4-test prelude smoke: install/TESTSTART/sweep all work, zero test failures under GC
    injection, and the grace design is confirmed necessary-and-sufficient at smoke scale —
    a heavy teardown leaves ~113 destroyed widgets alive through the IMMEDIATE double GC
    (turn/stack-pinned: the sweep runs inside the world cycle, and V8's conservative stack
    scanning sees the live frames above it), and ALL of them collect by the NEXT sweep —
    `tracked` fell 113 → 0 with zero `VMTRUTH` lines.
- **S1 — oracle noise + heap series at suite scale**: the D2 prelude in prototype form, run
  over the full dpr1 suite via `AUDIT_PRELUDE` (no gate, collect only). Deliverables:
  (a) per-teardown uncollected-survivor counts on today's green suite — identities of any
  non-zero result (each is either a REAL find → file/fix like Arc A's rounds, or an honest
  exemption with a written reason); (b) the per-page VMHEAP series → the slope statistic +
  threshold for D3, recorded here; (c) prelude overhead (suite wall-clock delta vs a plain
  run); (d) the grace-period verdict (is one teardown of grace needed, or is same-batch
  clean?).

  **S1 RESULTS (2026-08-20, full dpr1 suite × 8 shards under the prototype prelude):**
  - **307/307 tests PASSED, zero gate violations, 1.29 min wall-clock** — the per-teardown
    double-GC injection perturbs nothing (a plain run is ~1.1–1.3 min; overhead is noise).
  - **Collectibility: ZERO `VMTRUTH uncollected` lines across all 307 test buckets.** The
    gate ships with an EMPTY exemption table. (The string-keyed-LRU expectation held: the
    caches pin canvases, not widgets.)
  - **Grace verdict: one full teardown of grace is REQUIRED and SUFFICIENT.** A heavy
    teardown leaves up to ~2075 destroyed widgets alive through the immediate double GC
    (`tracked` high-water per page: 63–2075) — turn/stack-pinned, V8's conservative stack
    scanning sees the live frames above the in-cycle sweep — and every one collects by the
    next sweep on a leak-free suite.
  - **Heap series: post-GC used-heap starts ~53.6 MB on every page; NOT monotonic** (one
    page peaked at 214.8 MB mid-run and ended at 83 MB — heavy tests inflate, eviction
    deflates). Endpoint-vs-start statistics are therefore composition noise. The FLOOR
    statistic is stable: **floorGrowth = min(last 10 samples) − min(samples 3..15)**,
    measured per page at −14.9 to +44.4 MB on the green suite (8 pages × ~39 tests).
  - **D3 decision: gate `floorGrowth > 96 MB` per page (~2.2× the worst observed),
    skipping pages with < 20 samples** (stall-recovery reloads mint fresh pageIds with
    short series). A real leak grows with test count (~39 tests/page ⇒ even 3 MB/test
    trips it); legitimate floor growth is bounded caches + atlases and plateaus.
  - The wrapper's INVALID guard is validated by construction: all 307 buckets carried
    VMHEAP samples in this run, so "every bucket has ≥1 sample" is achievable and strict.
- **S2 — snapshot parser ground truth**: take a real snapshot of the harness page with a
  PLANTED closure-held widget; the D4 parser prototype must find it and print a retainer
  path naming the closure. (The tool is only trustworthy if it demonstrably sees a known
  leak — the D5 discipline applied to a tool.)

  **S2 RESULTS (2026-08-20) — ground truth achieved, with two mechanism corrections:**
  - ⚠ **Widget instances are ANONYMOUS (or wrongly named) in heap snapshots** — the
    meta-system's eval-built constructors leave V8 no reliable inferred name: the planted
    widget's node is `object "Object"`, and `world`'s RemoteObject className reads
    `window.IconGridPanelWdgt` (arbitrary). Name-based suspect finding is DEAD; D4
    identifies suspects by IDENTITY: `Runtime.queryObjects(Widget.prototype)` → filter
    in-VM to own-`instanceNumericID` carriers with `destroyed === true` →
    `HeapProfiler.getHeapObjectId` per element → match `s.nodeId(n)`.
  - ⚠ **Snapshot object ids are assigned lazily** — `getHeapObjectId` answers `"0"` until
    a snapshot exists. The tool's order is: take the snapshot FIRST, then map suspects to
    ids (ids are stable across the session).
  - The queryObjects cross-check found exactly the one planted destroyed widget
    (`RectangleWdgt#1`) on a pristine world — zero false positives.
  - The parser (plain `JSON.parse`, ~246k nodes in ~50 ms; reverse-BFS skipping `weak`
    edges) printed the full path naming plant, closure, and captured variable:
    `Window/file:// --property:WorldWdgt--> closure --property:__s2plantClosure-->
    --internal:context--> Context --context:w--> the widget`. That `context:w` line is
    the forensic value the in-band gate structurally cannot produce.
- **S3 — the named-target race** (`.scratch/promise-tail-probe.js`, drives `index.html` on
  the dev build): pick the barest door — `Widget.editLayout`'s
  `ensureLoaded('authoring').then => @showAdders(…)` tail (~:5575) — create/find a widget,
  invoke the door, `fullDestroy()` the widget SYNCHRONOUSLY after (the part load spans
  multiple frames over file://, so the tail is reliably pending), await the load, then
  record: does the tail throw / console-error / silently mutate the corpse? does the widget
  collect after GC once the promise settles? Repeat for one `whenAllLoaded` funnel site
  (e.g. `WindowedApp` ~:73). Deliverables: the observed failure mode(s) → D6's repair scope,
  and whether ensureLoaded's memoized per-part promise (`@_promises`, deleted on settle —
  PartsRegistry ~:122–130) can pin anything past resolution (expectation: no; verify).

  **S3 RESULTS (2026-08-20, `.scratch/vmtruth-s3-promise-tail-probe.js`) — the named
  target is REAL, and it is worse than retention:**
  - Door fired on two fresh widgets on `index.html`, both `fullDestroy()`ed while the
    `authoring` load was in flight (state LOADING). When the part arrived, the tail ran on
    the corpses with ZERO errors anywhere (no throw, no console error, no unhandled
    rejection) and: `corpseShowsAdders:true`, **`corpseChildrenCount:1`** — `showAdders`
    BUILT A FRESH AUTHORING WIDGET AND MOUNTED IT ON the destroyed, detached corpse. That
    child is registered in `Widget.instances`, its parent is a corpse no destroy cascade
    can ever reach — a permanent escaped widget (Arc A's escape class, manufactured by the
    race) on the one page that runs no inventory gate.
  - **Retention confirmed too:** the weakly-tracked corpse stays ALIVE after double GC —
    pinned via its new child (registry → child → `.parent` → corpse). Not transient.
  - The race window is real user territory: click "edit layout", close the window before
    the part lands.
  - ⇒ D6 repairs proceed (funnel-level guard), and the S3 race gets a durable home in the
    `parts` leg rigs (D6b).

## §6 Execution order and gates

| Phase | Work | Gate |
|---|---|---|
| 1 | S0–S3 spikes | numbers + verdicts recorded IN THIS DOC (§5); any S1/S3 product finds filed |
| 2 | D1 seam + D2 prelude + D3 wrapper | `vm-truth-gate.js` runs the full suite GREEN (exemptions only with written reasons); a no-gc run exits INVALID |
| 3 | D4 forensic tool (absorbs the rider) | tool finds the S2 plant end-to-end (run → lenses → retainer path) |
| 4 | D5 plants (all three) | Arc A gate SILENT on plant 1 while vmtruth FAILS it; slope FAILS plant 2; INVALID on plant 3; all plants removed |
| 5 | D6 repairs (if S3/S1 found defects) + D7 docs + fg leg | `fg presuite` for product edits; then full `fg gauntlet` (now 17 legs) + close ritual (archive + INDEX + memory + proposed commits, owner approval) |

Commit checkpoints: propose messages and WAIT (the standing owner rule); natural split =
(tests: seam+prelude+gate+tool) / (Fizzygum: repairs) / (docs+plan-archive), coordinated at
the end unless the owner asks mid-arc.

## §7 Central risks

- **GC pauses perturb suite timing.** The prelude leg runs dpr1 (the load-tolerant
  configuration), pauses land at the teardown seam (between tests, not mid-measurement), and
  a flip fails only the vmtruth leg — visible, not corrupting. If S1 shows test flips:
  diagnose via DETERMINISM.md before shipping the leg; a test that fails only under GC load
  is itself a find (the atlas-fuzz doctrine).
- **False-positive storm on the collectibility oracle** (the 1469 lesson): mitigated by
  S1-first, the one-teardown grace period, and gating identities (bounded list, named) rather
  than counts.
- **Slope threshold guessed instead of measured**: forbidden by construction — D3's
  statistic is an S1 deliverable, and the gate ships only after the series is eyeballed.
- **Snapshot memory blow-up in Node**: retired by S0's measurement (24 MB on the booted
  world); the tool keeps a size cap and reports rather than OOMs if a future heap balloons.
- **A prelude that silently didn't install** reads as a green gate: killed by the
  every-log-has-a-sample INVALID guard (self-proving measurement).
- **`page.queryObjects` deprecation drift** across Puppeteer versions: S0 pins the spelling;
  the CDP fallback (`Runtime.queryObjects`) is version-stable.

## §8 Rejected alternatives (do not re-attempt blind)

- **`FinalizationRegistry` as the gating oracle** — same question as a WeakRef deref, but
  answered via callbacks whose scheduling is unspecified even after a forced GC (host-defined
  task timing); a gate on them needs sleeps and retry loops and still flakes. The WeakRef
  sweep is the same oracle made synchronous. FR is not used at all in this arc; if Arc C
  wants an ambient always-on collectibility signal (no forced GC available in production),
  that is a different design conversation.
- **Runner-side per-test CDP hooks in `run-all-headless.js`** — re-rejected from Arc A §8:
  the runner has no per-test callback (1 Hz poll), retrofitting one couples the suite's
  stall/crash machinery to CDP timing, and the prelude seam already delivers per-teardown
  precision in-page.
- **A dedicated serial full-suite VM runner** (one browser, own page handle, queryObjects
  every teardown) — ~5 min single-process vs ~2 min sharded via the prelude rail, duplicates
  run-all's stall/recovery machinery, and the only thing it adds (per-teardown queryObjects)
  is redundant with the WeakRef sweep for GATING purposes; queryObjects' unique value
  (registration-hole detection) lives in the on-demand tool where a page handle is free.
- **Gating `page.metrics()`/heap WITHOUT forced GC** — heap size without GC is dominated by
  collection scheduling noise; the slope would gate the GC heuristics, not the code.
- **A `VM_TRUTH` entry in `lib/gate-tokens.js`** — the tokens gate ALWAYS-ON in-page guards;
  this gate's lines exist only under its own prelude, and its wrapper is its gate (the
  storage Tier-B precedent).

## §9 References

- Program + Arc A execution ledger: `docs/archive/world-inventory-instruments-plan.md`
  (§0 program, §5.1/§5.2 rounds, §8 deferrals this arc now redeems).
- Doctrine: `docs/architecture/world-lifetime-and-inventory.md`.
- Prelude/gate templates: `Fizzygum-tests/scripts/audit-preludes/storage-audit-prelude.js`,
  `Fizzygum-tests/scripts/storage-invariant-gate.js`; INVALID doctrine:
  `Fizzygum-tests/scripts/run-atlas-fuzz.js` header.
- Memory: `world-object-lifetime-program`, `atlas-delay-fuzz-tool-arc` (a gate must prove it
  measured), `no-conclusions-before-evidence`, `resetworld-state-leak-between-tests`
  (attribution semantics), `suite-nondeterminism-flakes-arc`.
- Code anchors (re-grep, don't trust lines): `unregisterThisInstance`,
  `registerThisInstance`, `_auditWorldInventoryNoSettle`, `AUDIT_PRELUDE`, `AUDIT_CHROME_ARGS`
  (D1, to be created), `launchChrome`, `LAYOUTAUDIT_TESTSTART`, `ensureLoaded`,
  `whenAllLoaded`, `showAdders`, `instanceNumericID`.

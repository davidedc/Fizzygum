'use strict';
// not-a-gate: the table of fg's gauntlet legs and its reader for fg (`--shell`) — the programs its rows name are the gates
// legs.js — THE GAUNTLET'S LEGS, one row each: what `fg` runs at a commit point (`fg gauntlet`, its parallel waves and
// its serial path) and in its inner loop (`fg presuite`). `fg` stays the entry point and keeps what is its own — the
// verdict files, the `to` alarm, keeping the machine awake, killing browsers, backgrounding a wave, the serial retry,
// the tally —; it asks this table WHICH legs there are and HOW each one runs (`node buildSystem/legs.js --shell …`),
// so the waves, the serial path, the stale-proofing of the leg logs and the usage roster cannot name different legs.
// The comments above each row are fg's own, verbatim, moved from `run_leg`'s case arms (the precedent: gates.js, the
// build's gate table, whose comments moved from build_it_please.sh). lib/what-runs.js reads the rows to know what the
// legs launch, and refuses a row no wave and no presuite schedules: a leg nothing runs would vouch for its programs.
//
// A row:
//   name      the leg's name (`/tmp/fg-<name>.log`)
//   waves     where it runs: a gauntlet wave ('A'..'D', run in that order, each wave's legs at once) and/or 'presuite'
//   steps     what it runs, in order, each in its own subshell, the log truncated once and then appended to; the first
//             step that fails ends the leg with its exit code. A step is
//               { suite: [flags…] }                          fg_suite (the suite runner, its kill and its alarm), or
//               { cwd: 'tests'|'fizzygum', alarm: <s>, script, args: [] }  `( cd … && to <alarm> node <script> <args> )`
//             An argument `{SUITE_SHARDS}` or `{GATE_SHARDS}` is the shard count fg's caller sets for the run
//             (`${FG_SUITE_SHARDS:-4}`, `${FG_GATE_SHARDS:-6}`), expanded when the leg runs.
//   passLine  a line the log must also hold for the leg to pass (its program's own verdict line)
//   infraExit true for a leg whose exit 3 is an INFRA flake (the six audited-suite gates' shard dropped twice): a
//             warning, never a FAIL. Any other leg's 3 is a failure like any other non-zero exit.
//   headline  the lines of its log fg shows under the leg's name after a wave (grep -E), last two matches
//   verb      the standalone `fg` verb that runs the same program, if any (its own command line, in fg)
//
// Its cases: legs-selftest.js (the table's own rules, and the reader fg runs, on a small table).

// the headline of a leg whose log relays a suite run's summary
const SUITE = 'wall-clock|failed tests';

const LEGS = [
  // ---- wave A
  { name: 'dpr1', waves: ['presuite', 'A'],
    steps: [{ suite: ['--shards={SUITE_SHARDS}'] }],
    headline: SUITE, verb: 'suite' },
  { name: 'dpr2', waves: ['A'],
    steps: [{ suite: ['--dpr=2', '--shards={SUITE_SHARDS}'] }],
    headline: SUITE },
  { name: 'webkit', waves: ['A'],
    steps: [{ suite: ['--browser=webkit', '--shards={SUITE_SHARDS}'] }],
    headline: SUITE },
  { name: 'apps', waves: ['A'],
    steps: [{ cwd: 'tests', alarm: 300, script: 'scripts/smoke-apps-headless.js', args: [] }],
    headline: 'APPS (OK|FAILED)',
    passLine: 'APPS OK', verb: 'apps' },
  // LAZY PARTS (arc 4 phase 2). Two rigs the suite structurally CANNOT cover: every SystemTest
  // runs on worldWithSystemTestHarness.html, which presets FIZZYGUM_EAGER_ALL_PARTS so no part is
  // ever lazy there (a part arriving mid-test would be frame-paced ⇒ cycle-count-dependent ⇒ the
  // DETERMINISM.md bug class). So laziness is only real on index.html, and only these two see it:
  // the load path (icon present, engine + 3D vendor absent, click ⇒ loads ⇒ renders pixels) and
  // the snapshot path (a saved world naming a class from an unloaded part loads it first — plus
  // the ORDERING assertion that a FAILED part load leaves the desktop standing, which is what
  // pins the pre-scan above loadWorldSnapshot's teardown). ~1 min for both.
  // `parts` rides in wave A, not B: it is 27s and light, but wave B already runs ~26
  // concurrent browsers (paint 5 + four 4-shard gates + storage 4 + census + serialization)
  // and adding a 14th leg there tipped it — serialization's 30s boot timed out and a paint
  // shard failed to boot, both passing on the serial retry. Wave A is ~20 browsers (selftests
  // holds up to six at a time).
  { name: 'parts', waves: ['A'],
    steps: [{ cwd: 'tests', alarm: 300, script: 'scripts/parts-lazy-load-headless.js', args: [] },
      { cwd: 'tests', alarm: 300, script: 'scripts/parts-snapshot-load-headless.js', args: [] },
      { cwd: 'tests', alarm: 420, script: 'scripts/parts-lazy-icons-headless.js', args: [] }],
    headline: SUITE + '|LAZY PART (LOAD|SNAPSHOT LOAD) (OK|FAILED)', verb: 'lazyprobe' },
  // MENU CLICK SWEEP: fires every reachable menu item's ACTION and fails on a throw. The runtime
  // half of menu-action wiring; its static half (check-menu-actions.js) runs on the build. The gate
  // sees the shapes a text scan can see; this sees a parameter that IS read and is read as the
  // WRONG THING — createOpener asked a MenuItemWdgt for its `.contents` and crashed on every click,
  // and three SliderWdgt prompts threw behind a runtime tripwire nothing ever tripped, because the
  // suite drives menus heavily but does not click EVERY item.
  { name: 'menusweep', waves: ['A'],
    steps: [{ cwd: 'tests', alarm: 300, script: 'scripts/menu-click-sweep-headless.js', args: [] }],
    headline: 'MENU CLICK SWEEP', verb: 'menusweep' },
  // EVERY PIN A CLASS ADVERTISES MUST BE SERVICEABLE. A PinSpec names its setter by STRING and the
  // dataflow dispatches it as consumer[name]?.call, so an unresolved one is offered, accepts a
  // wire, and silently does nothing forever. Runtime, not static, because pins() is COMPOSED and a
  // subclass can NARROW it — a text scan reports pins a class does not have. Its appearance section
  // found `corner radius` advertised by 16 classes with no setCornerRadius, which was ALSO a hard
  // throw in the shape's own prompt — a two-step gesture menusweep structurally cannot reach.
  { name: 'pinsweep', waves: ['A'],
    steps: [{ cwd: 'tests', alarm: 300, script: 'scripts/pin-sweep-headless.js', args: [] }],
    headline: 'pin-sweep', verb: 'pinsweep' },
  // THE WIDGET-GRAPH LIVENESS CONTRACT (graph-edges §4.3 promotion). The `storage` leg gates the
  // classifier's IDEMPOTENCE; this gates its SEMANTICS through the REAL drain station: wire death
  // severs the living producer's record (no re-declaration/delivery into a corpse), the collector
  // files by containment ∪ flow ∪ reference (command confers nothing), close asks the same
  // question (anyReferenceOrWireIntoWdgt), and graphEdgesOut terminates on the ex-double-injection
  // mixin chain. One browser, ~35s. Fails on any check, STORAGE_INVARIANT token or console error.
  { name: 'graph', waves: ['A'],
    steps: [{ cwd: 'tests', alarm: 300, script: 'scripts/graph-liveness-headless.js', args: [] }],
    headline: 'graph-liveness\\] OK|graph-liveness FAILED', verb: 'graph' },
  // THE HEADLESS SELF-TESTS (unrun-checks arc): every *-selftest-headless.js, found by NAME
  // (Fizzygum/buildSystem/lib/what-runs.js) — the proofs that need the built page: every audit
  // prelude installs clean (incl. the ones only a person injects), heap-forensics sees a planted
  // closure leak, the settle leg's cached-vs-SLOW oracle bites, and EVERY gauntlet leg's bite-proof
  // runs that leg's gate on planted input and plants each of its rules (control, plants, INVALIDs).
  // The node-tier self-tests run on every BUILD. Files run six at a time (run-selftests.js's
  // HEADLESS_POOL), longest first: ~153 s alone, ~212 s inside a loaded wave A — the budget is
  // wave A's longest leg (every-gate-bites arc, 2026-11-07).
  { name: 'selftests', waves: ['A'],
    steps: [{ cwd: 'fizzygum', alarm: 600, script: 'buildSystem/run-selftests.js', args: ['--headless'] }],
    headline: '\\[selftests\\] (OK|FAIL)' },
  // ---- wave B
  // paint-truthfulness gate (plan 5.3): the whole suite must stay paint-truthful — a forced full repaint of each
  // test's settled end-state must not change any pixel (a delta = a dropped invalidation / D2-class ghost region).
  // It runs as the `paint` leg in run_leg does (five shards): one browser cannot audit the whole suite inside
  // the audit's own 600 s bound (measured 2026-11-14: 389 tests, 0 checked at 600 s, at load 9).
  { name: 'paint', waves: ['presuite', 'B'],
    steps: [{ cwd: 'tests', alarm: 720, script: 'scripts/run-paint-audit.js', args: ['--shards=5'] }],
    headline: SUITE + '|GATE (PASSED|FAILED|INVALID)|OFFENDERS \\(' },
  // runtime audit gates (layering/naming §5b/§9.6, end-of-cycle drawdown §8): the apply-2x2 lattice, callback
  // settle-neutrality, careless end-of-cycle pushes + paint-time schedules. ~1.5 min each.
  { name: 'tiernaming', waves: ['B'],
    steps: [{ cwd: 'tests', alarm: 900, script: 'scripts/tier-naming-audit/tier-naming-gate.js', args: ['{GATE_SHARDS}'] }],
    headline: SUITE + '|GATE (PASSED|FAILED|INVALID)', infraExit: true },
  { name: 'settle', waves: ['B'],
    steps: [{ cwd: 'tests', alarm: 900, script: 'scripts/notification-settle-audit/settle-gate.js', args: ['{GATE_SHARDS}'] }],
    headline: SUITE + '|GATE (PASSED|FAILED|INVALID)', infraExit: true },
  { name: 'capstone', waves: ['B'],
    steps: [{ cwd: 'tests', alarm: 900, script: 'scripts/end-of-cycle-audit/capstone-gate.js', args: ['{GATE_SHARDS}'] }],
    headline: SUITE + '|GATE (PASSED|FAILED|INVALID)', infraExit: true },
  // reference PIXEL integrity (no browser): decode every SWCanvas ref (1842 and growing — the count
  // tracks the suite) and assert each re-hashes to its stored hashOfData. The build's check-refs call
  // is STRUCTURAL only (0.2s) — this is the pixel half, kept off the build because paying it on every
  // inner-loop build to check refs that only change on a recapture is a bad trade.
  // ⚠ The budget is for the LOADED case, not the quiet one: standalone it is seconds, but sharing a
  // wave with five browser legs it measured 76s once and BLEW a 120s alarm the same day (rc=142,
  // SIGALRM — which reads as a leg failure and costs a serial retry). It scales with the reference
  // count, so keep the headroom generous rather than tracking the measurement.
  // Rides with the pixel check: check-visualisations --strict requires each committed
  // visualisation.html to EQUAL what make-visualisation.js produces now (freshness, not just
  // the resolution half that is already on every build). Same build-vs-commit-point split as
  // check-refs itself: the cheap structural half gates the BUILD, the fuller one rides a leg,
  // so a page-template edit is caught at a commit point instead of blocking every inner-loop
  // build until all pages are regenerated. ~1s, no browser.
  // And the DOCS ratchet (check-doc-narration.js, a hard zero): docs prose must not block a
  // BUILD, so it is checked at the commit point, here, rather than only when someone runs it.
  // The pixel check decodes every reference (~4.1k PNGs): 244-286s inside a gauntlet wave by
  // 2026-11-09, so its alarm sits well above that (it timed out once at 300s under wave load).
  { name: 'refs', waves: ['B'],
    steps: [{ cwd: 'tests', alarm: 420, script: 'scripts/check-refs.js', args: ['--pixels', '--quiet'] },
      { cwd: 'tests', alarm: 120, script: 'scripts/check-visualisations.js', args: ['--strict', '--quiet'] },
      { cwd: 'fizzygum', alarm: 60, script: 'buildSystem/check-doc-narration.js', args: [] }],
    headline: 'FAIL|verified consistent|consistency FAILED', verb: 'doc-narration' },
  // settle-re-visit standing gate (up-edge endgame close, 2026-07-17): one dpr1 suite pass under
  // the counting prelude; the profile must equal the committed baseline — which is EMPTY, so ANY
  // re-visit anywhere = a convergence regression. Wave-sized via FG_GATE_SHARDS like the other
  // gates; standalone `fg revisits` runs the gate's own default (6 shards).
  { name: 'revisits', waves: ['B'],
    steps: [{ cwd: 'tests', alarm: 900, script: 'scripts/revisit-gate.js', args: ['{GATE_SHARDS}'] }],
    headline: SUITE + '|revisit-gate: (OK|FAILED|INVALID)|DRIFT |GATE INVALID', infraExit: true, verb: 'revisits' },
  // arrange-idempotence oracle (owner-directed 2026-07-17, same close as revisits): ONE page,
  // battery + post-order force-re-lay sweep in a single evaluate — ~10s, free inside the wave.
  { name: 'census', waves: ['B'],
    steps: [{ cwd: 'tests', alarm: 300, script: 'scripts/staleness-census.js', args: [] }],
    headline: 'CENSUS (OK|FAILED)', verb: 'census' },
  // serialization gates (promoted 2026-07-22, owner-directed — its 22 spreadsheet checks had
  // sat broken and UNNOTICED since the 2026-07-19 SpreadsheetWdgt rename because nothing ran
  // the rig at commit points): the round-trip characterization rig (widget + world legs,
  // native + SWCanvas, ONE browser, ~3 min) then the file:// save/load rig. Both must pass.
  { name: 'serialization', waves: ['B'],
    steps: [{ cwd: 'tests', alarm: 900, script: 'scripts/serialization-roundtrip-headless.js', args: [] },
      { cwd: 'tests', alarm: 300, script: 'scripts/serialization-file-roundtrip-headless.js', args: [] }],
    headline: SUITE + '|SERIALIZATION RIG (OK|FAILED)|FILE ROUND-TRIP (OK|FAILED)' },
  // bin/shelf storage DEEP AUDIT (Tier B, bin-shelf-eager-sorting-plan.md Phase 5): one dpr1
  // suite pass under the storage prelude — per-test force-drain + FROM-SCRATCH reclassify
  // asserting ZERO moves (idempotence) + structural residue; the profile must be EMPTY (no
  // baseline file on purpose). Tier A (the STORAGE_INVARIANT console token) already rides
  // every suite leg; this leg catches classifier self-disagreement, which Tier A cannot.
  { name: 'storage', waves: ['B'],
    steps: [{ cwd: 'tests', alarm: 900, script: 'scripts/storage-invariant-gate.js', args: ['{GATE_SHARDS}'] }],
    headline: SUITE + '|storage-gate: (OK|FAILED|INVALID)|GATE INVALID', infraExit: true, verb: 'storage' },
  // ---- wave C
  // VM-truth object-lifetime gate (Arc B, world-vm-truth-riders plan): one dpr1 suite pass
  // under the forced-GC prelude — every destroyed widget must be GC-collectible one teardown
  // later (closure retention the in-band WORLD_INVENTORY gate cannot see) + the post-GC
  // heap-floor ceiling; exit 2 = INVALID (measured nothing — the wrapper refuses to read an
  // unmeasured run as green). Chrome-only by design; the webkit leg keeps the in-band tier.
  // vmtruth runs ALONE as wave C, not inside B: it is itself a full-suite pass and wave B
  // already tipped the box once at 14 legs (serialization boot timeouts) — +~100s of
  // gauntlet is cheaper than an infra-flake retry lottery. Alone it gets full shards.
  { name: 'vmtruth', waves: ['C'],
    steps: [{ cwd: 'tests', alarm: 900, script: 'scripts/vm-truth-gate.js', args: ['{GATE_SHARDS}'] }],
    headline: SUITE + '|vm-truth-gate: (OK|FAILED|INVALID)|GATE INVALID', infraExit: true, verb: 'vmtruth' },
  // ---- wave D
  // THE FINGER LEG (Plan 4): the whole suite replayed as a FINGER — the toolkit translates every
  // intent verb into the touch gesture carrying the same intent, and the run matches the finger
  // reference axis (…/ceilPixRatio_<N>/finger/). WebKit + dpr2 = "an iPad" for this suite's
  // purposes (ruling H2); references are captured on Chrome and reused, as the mouse ones are.
  // finger runs ALONE as wave D, like vmtruth and for the same reason: it is itself a
  // full-suite pass — at dpr2 under WebKit, the heaviest single leg — and wave B already
  // tipped the box once at 14 legs.
  { name: 'finger', waves: ['D'],
    steps: [{ suite: ['--pointer=finger', '--browser=webkit', '--dpr=2', '--shards={SUITE_SHARDS}'] }],
    headline: SUITE, verb: 'finger' },
  // ---- the presuite alone
  // fractional-plane dpr2 rider (PRESUITE-ONLY): the reparent-transparency figure landing is
  // the one legitimately-fractional plane-geometry class, and every pixel divergence it can
  // cause rounds identically at dpr 1 — the dpr1 suite is BLIND to it; only a dpr2 render sees
  // a regression (appearance local-coords arc: a real one shipped through three green
  // presuites and was caught only by the close gauntlet). This leg is the inner loop's only
  // dpr2 eye, over exactly the two fractional-scene tests; the gauntlet's full dpr2 leg
  // subsumes it, so it is deliberately NOT a gauntlet leg.
  { name: 'fracplane', waves: ['presuite'],
    steps: [{ cwd: 'tests', alarm: 300, script: 'scripts/run-sequence-headless.js', args: ['--dpr=2', 'SystemTest_macroDropIntoRotatedStretchablePanelStretchesOnResize', 'SystemTest_macroDropStrokedRectIntoRotatedPanel'] }],
    headline: 'run-sequence:|failed  :', verb: 'run-sequence' },
];

const WAVES = ['A', 'B', 'C', 'D'];
const PLACES = new Set([...WAVES, 'presuite']);
const SHARDS = ['{SUITE_SHARDS}', '{GATE_SHARDS}'];
const CWDS = new Set(['tests', 'fizzygum']);
// what fg_suite runs (in the tests repo) for a suite step
const SUITE_RUNNER = 'scripts/run-all-headless.js';

// Every reason the table cannot be run, as lines (empty: it can). A name twice; a row no wave and no presuite schedules
// (it would vouch, in lib/what-runs.js, for programs nothing runs); an unknown place; a wave holding no leg; a step that
// is neither a suite step nor a script step with a known cwd, a positive alarm and a script; a placeholder this table
// does not define; a headline that is no regular expression.
function tableErrors(legs = LEGS) {
  const errors = [], seen = new Set();
  for (const r of legs) {
    const at = 'leg ' + JSON.stringify(r.name);
    if (!r.name || !/^[a-z0-9-]+$/.test(r.name)) errors.push(at + ': a name is lower-case letters, digits and dashes');
    if (seen.has(r.name)) errors.push(at + ': named twice');
    seen.add(r.name);
    if (!Array.isArray(r.waves) || !r.waves.length) errors.push(at + ': no wave and no presuite runs it');
    else for (const w of r.waves) if (!PLACES.has(w)) errors.push(at + ': unknown place ' + JSON.stringify(w));
    if (!Array.isArray(r.steps) || !r.steps.length) errors.push(at + ': no step');
    else for (const s of r.steps) {
      const words = s.suite || s.args || [];
      if (s.suite) { if (s.script || s.cwd || s.alarm) errors.push(at + ': a suite step is fg_suite\'s alone (its alarm and cwd)'); }
      else if (!CWDS.has(s.cwd) || !(s.alarm > 0) || !s.script || !Array.isArray(s.args)) errors.push(at + ': a step is { suite } or { cwd, alarm, script, args }');
      for (const w of words) for (const m of String(w).match(/\{[A-Z_]+\}/g) || []) if (!SHARDS.includes(m)) errors.push(at + ': unknown placeholder ' + m);
      for (const w of words) if (typeof w !== 'string' || !w.length || /[\t\n]/.test(w)) errors.push(at + ': an argument is a non-empty string with no tab or line break');
      if (s.script !== undefined && (typeof s.script !== 'string' || /[\t\n ]/.test(s.script))) errors.push(at + ': a script is a path with no tab, space or line break');
    }
    try { new RegExp(r.headline); } catch (e) { errors.push(at + ': its headline is no regular expression'); }
    for (const [field, v] of [['headline', r.headline], ['passLine', r.passLine]]) {
      if (v !== undefined && (typeof v !== 'string' || !v.length || /[\t\n]/.test(v))) errors.push(at + ': its ' + field + ' is a non-empty line with no tab');
    }
  }
  for (const w of WAVES) if (!legs.some((r) => (r.waves || []).includes(w))) errors.push('wave ' + w + ' holds no leg');
  return errors;
}

// The legs a place runs, by name: a wave letter or 'presuite' (table order), 'gauntlet' (every leg in a wave, wave by
// wave: the order of the parallel path's launches and of the serial path), 'infra' (the legs whose exit 3 is an infra
// flake).
function legsIn(where, legs = LEGS) {
  if (where === 'gauntlet') return WAVES.flatMap((w) => legsIn(w, legs));
  if (where === 'infra') return legs.filter((r) => r.infraExit).map((r) => r.name);
  if (!PLACES.has(where)) throw new Error('no place ' + JSON.stringify(where) + ' (a wave ' + WAVES.join('/') + ', presuite, gauntlet or infra)');
  return legs.filter((r) => r.waves.includes(where)).map((r) => r.name);
}
function legNamed(name, legs = LEGS) {
  const r = legs.find((x) => x.name === name);
  if (!r) throw new Error('no leg named ' + JSON.stringify(name) + ' in buildSystem/legs.js');
  return r;
}

// A row as fg's run_leg reads it, one tab-separated line each: `passline<TAB><line>` first when the row has one (fg
// reads it before the steps, since a failing step ends the reading), then a line per step — `suite<TAB><flag>…` or
// `step<TAB>tests|fizzygum<TAB><alarm><TAB><script><TAB><arg>…`.
function rowLines(name, legs = LEGS) {
  const r = legNamed(name, legs);
  const lines = r.passLine ? ['passline\t' + r.passLine] : [];
  for (const s of r.steps) lines.push(s.suite ? ['suite', ...s.suite].join('\t') : ['step', s.cwd, s.alarm, s.script, ...s.args].join('\t'));
  return lines;
}

// fg's usage lines that name legs: the presuite's, the gauntlet's waves (A and B listed, a one-leg wave "alone"), the
// serial retry, and the gates whose exit 3 is an infra flake (the line that follows them is fg's own).
function roster(legs = LEGS) {
  const pad = ' '.repeat(44);
  const list = (w) => '[' + legsIn(w, legs).join('|') + ']';
  const alone = WAVES.slice(2).map((w) => (legsIn(w, legs).length === 1 ? legsIn(w, legs)[0] + ' alone' : list(w)) + ' (wave ' + w + ')');
  return ['  fg presuite [buildflags]                  INNER LOOP: build + ' + legsIn('presuite', legs).join(' ∥ ') + ' at once (~3-4 min)',
    '  fg gauntlet                               build + PARALLEL waves: ' + list('A') + ' then',
    pad + list('B') + ',', pad + 'then ' + alone.join(', then ') + ';',
    pad + 'a failed leg gets ONE serial retry (pass ⇒ load-flake warning, not a FAIL).',
    pad + 'The AUDITED-SUITE gates (' + legsIn('infra', legs).join('|') + ':'];
}

module.exports = { LEGS, WAVES, SUITE_RUNNER, tableErrors, legsIn, legNamed, rowLines, roster };

// fg's reader: `node buildSystem/legs.js --shell <what>` prints, for bash 3.2 to read —
//   names <wave|presuite|gauntlet|infra>   the legs, space-separated
//   row <name>                             rowLines, one per line
//   headline <name>                        the leg's headline pattern
//   banner <wave|presuite>                 the legs joined by ' ∥ ' (a wave's banner)
//   roster                                 the usage roster lines
// A table that cannot be run, an unknown leg or place, or anything else exits 2, saying why: fg then refuses to run
// rather than run a wave of nothing.
if (require.main === module) {
  const [flag, what, arg] = process.argv.slice(2);
  const fail = (m) => { process.stderr.write('legs.js: ' + m + '\n'); process.exit(2); };
  if (flag !== '--shell') fail('usage: node buildSystem/legs.js --shell names|row|headline|banner|roster …');
  const errors = tableErrors();
  if (errors.length) fail('the leg table cannot be run:\n  ' + errors.join('\n  '));
  try {
    if (what === 'names') console.log(legsIn(arg).join(' '));
    else if (what === 'row') console.log(rowLines(arg).join('\n'));
    else if (what === 'headline') console.log(legNamed(arg).headline);
    else if (what === 'banner') console.log(legsIn(arg).join(' ∥ '));
    else if (what === 'roster') console.log(roster().join('\n'));
    else fail('unknown request ' + JSON.stringify(what));
  } catch (e) { fail(e.message); }
}

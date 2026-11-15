#!/usr/bin/env node
'use strict';
// legs-selftest.js — the cases of the gauntlet's leg table (legs.js) and of fg's runner that reads it: a COPY of fg's
// commit point (fg-commit-point.js, with lib/fg-supervisor.js) in a temp workspace, beside a SMALL table written with
// legs.js's own code, whose steps are tiny node scripts that print their arguments and working directory and exit as
// told (a stand-in suite runner, and a stand-in `pkill` first on PATH, so no real browser is touched; the copy's logs go
// to its own temp directory through fg's FG_TMP test rail). So it holds, end to end: the order (the gauntlet's waves
// A..D, a wave's legs in table order), a FAILING row (its first failing step ends it with that step's exit code, the
// steps after it never run), exit 3 (an INFRA flake for a leg the table marks so, a failure for any other), a pass line,
// the shard placeholders, each step's cwd, a leg the table does not hold (a hard failure) and a leg no wave ran
// (NEVER-RAN). Then the table's own rules (tableErrors) on broken tables, and the REAL table: it can be run, every step's
// script exists, every verb a row names is one fg defines, and fg's commit point reads every list it uses from it.
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const { cases } = require('./lib/selftest-verdict');
const L = require('./legs');

const t = cases('legs');
const FIZZYGUM = path.resolve(__dirname, '..');
const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'legs-selftest-'));
const FZ = path.join(temp, 'Fizzygum'), FT = path.join(temp, 'Fizzygum-tests');
// every leg here writes <its temp dir>/fg-<name>.log (fg's FG_TMP rail): a prefix no real leg has all the same
const P = 'legs-selftest-' + process.pid + '-';
const TMP = path.join(temp, 'tmp'), BIN = path.join(temp, 'bin');

// ---- a small table, beside a copy of legs.js's code
const STEP = (cwd, script, ...args) => ({ cwd, alarm: 30, script, args });
const SMALL = [
  { name: P + 'a1', waves: ['A'], steps: [STEP('tests', 'scripts/ok.js', 'one'), STEP('fizzygum', 'buildSystem/ok.js', '{GATE_SHARDS}')], headline: 'x' },
  { name: P + 'a2', waves: ['A', 'presuite'], steps: [{ suite: ['--dpr=2', '--shards={SUITE_SHARDS}'] }], headline: 'x' },
  { name: P + 'b1', waves: ['B'], steps: [STEP('tests', 'scripts/ok.js', 'first'), STEP('tests', 'scripts/exit.js', '5'), STEP('tests', 'scripts/ok.js', 'never')], headline: 'x' },
  { name: P + 'c1', waves: ['C'], steps: [STEP('tests', 'scripts/exit.js', '3')], infraExit: true, headline: 'x' },
  { name: P + 'd1', waves: ['D'], steps: [STEP('tests', 'scripts/exit.js', '3')], headline: 'x' },
  { name: P + 'p1', waves: ['presuite'], steps: [STEP('tests', 'scripts/ok.js', 'VERDICT LINE')], passLine: 'VERDICT LINE', headline: 'x' },
  { name: P + 'p2', waves: ['presuite'], steps: [STEP('tests', 'scripts/ok.js', 'no verdict')], passLine: 'VERDICT LINE', headline: 'x' },
];
const write = (rel, text) => { fs.mkdirSync(path.dirname(path.join(temp, rel)), { recursive: true }); fs.writeFileSync(path.join(temp, rel), text); };
const code = fs.readFileSync(path.join(__dirname, 'legs.js'), 'utf8');
const start = code.indexOf('\nconst LEGS = [\n'), end = code.indexOf('\n];\n', start);
t.check(start > 0 && end > start, 'legs.js holds its table as `const LEGS = [ … ];`');
write('Fizzygum/buildSystem/legs.js', code.slice(0, start) + '\nconst LEGS = ' + JSON.stringify(SMALL, null, 1) + ';\n' + code.slice(end + 4));
const OK = "console.log('ran ' + process.argv.slice(2).join(' ') + ' in ' + process.cwd());\n";
write('Fizzygum-tests/scripts/ok.js', OK);
write('Fizzygum/buildSystem/ok.js', OK);
write('Fizzygum-tests/scripts/exit.js', "console.log('exiting ' + process.argv[2]); process.exit(Number(process.argv[2]));\n");

// ---- a copy of fg's commit point, its supervisor, a stand-in suite runner and a stand-in pkill
write('Fizzygum/buildSystem/fg-commit-point.js', fs.readFileSync(path.join(__dirname, 'fg-commit-point.js'), 'utf8'));
write('Fizzygum/buildSystem/lib/fg-supervisor.js', fs.readFileSync(path.join(__dirname, 'lib', 'fg-supervisor.js'), 'utf8'));
write('Fizzygum-tests/scripts/run-all-headless.js', "console.log('suite ' + process.argv.slice(2).join(' ') + ' in ' + process.cwd());\n");
write('bin/pkill', '#!/bin/sh\nexit 1\n');
fs.chmodSync(path.join(BIN, 'pkill'), 0o755);
fs.mkdirSync(TMP, { recursive: true });
const COPY = path.join(FZ, 'buildSystem', 'fg-commit-point.js');
// one node process running `code` with C = the copy of fg's commit point
function node(code) {
  const r = spawnSync(process.execPath, ['-e', 'const C = require(' + JSON.stringify(COPY) + ');\n(async () => {\n' + code + '\n})().catch((e) => { console.error(e); process.exitCode = 9; });'],
    { encoding: 'utf8', env: { PATH: BIN + ':' + process.env.PATH, HOME: process.env.HOME, FG_TEST_RAILS: '1', FG_TMP: TMP } });
  return { status: r.status, out: r.stdout.trim(), err: r.stderr.trim() };
}
const logOf = (name) => { try { return fs.readFileSync(path.join(TMP, 'fg-' + name + '.log'), 'utf8'); } catch (e) { return ''; } };
// run_leg <name>, the shell variables set as fg sets them (never exported to the steps)
const runLeg = (name, vars = {}) => {
  const r = node(Object.entries(vars).map(([k, v]) => 'C.setVar(' + JSON.stringify(k) + ', ' + JSON.stringify(v) + ');').join('') +
    'console.log("rc=" + await C.runLeg(' + JSON.stringify(name) + '));');
  return { rc: Number((/rc=(\d+)/.exec(r.out) || [])[1]), log: logOf(name), err: r.err };
};
const names = (where) => { const r = node('const x = C.tableNames(' + JSON.stringify(where) + '); console.log(x.error ? "ERROR " + x.error : x.names.join(" "));'); return r.out + r.err; };

try {
  // the order, a wave, the presuite
  let r = names('gauntlet');
  t.check(r === [P + 'a1', P + 'a2', P + 'b1', P + 'c1', P + 'd1'].join(' '), 'the gauntlet\'s legs: wave by wave, A..D, each in table order', r);
  r = names('A');
  t.check(r === P + 'a1 ' + P + 'a2', 'a wave\'s legs', r);
  r = names('presuite');
  t.check(r === [P + 'a2', P + 'p1', P + 'p2'].join(' '), 'the presuite\'s legs, in table order', r);
  r = names('nowhere');
  t.check(/^ERROR legs\.js: no place "nowhere"/.test(r), 'an unknown place: fg refuses it, saying why', r);

  // a passing row: each step in its own cwd, the placeholders the caller's shard counts, the log appended step by step
  let leg = runLeg(P + 'a1', { FG_GATE_SHARDS: '4' });
  t.check(leg.rc === 0, 'a row whose steps pass passes', JSON.stringify(leg));
  t.check(leg.log.includes('ran one in ' + fs.realpathSync(FT)) && leg.log.includes('ran 4 in ' + fs.realpathSync(FZ)),
    'each step runs in its cwd (tests / fizzygum), the {GATE_SHARDS} placeholder the caller\'s FG_GATE_SHARDS', leg.log);
  t.check(new RegExp('fg-leg: ' + P + 'a1 rc=0 \\d+s').test(leg.log), 'the leg log ends with fg\'s `fg-leg:` stamp', leg.log);
  leg = runLeg(P + 'a1');
  t.check(leg.log.includes('ran 6 in '), '{GATE_SHARDS} defaults to 6', leg.log);
  leg = runLeg(P + 'a2', { FG_SUITE_SHARDS: '8' });
  t.check(leg.rc === 0 && leg.log.includes('suite --dpr=2 --shards=8 --shards=8 in ' + fs.realpathSync(FT)),
    'a suite step is the suite runner with its flags, {SUITE_SHARDS} the caller\'s, fg\'s --shards=8 last', leg.log);
  leg = runLeg(P + 'a2');
  t.check(leg.log.includes('suite --dpr=2 --shards=4 --shards=8'), '{SUITE_SHARDS} defaults to 4', leg.log);

  // a failing row: its first failing step ends it, with that step's exit code
  leg = runLeg(P + 'b1');
  t.check(leg.rc === 5, 'a failing step ends the leg with ITS exit code', JSON.stringify(leg.rc));
  t.check(leg.log.includes('ran first') && leg.log.includes('exiting 5') && !leg.log.includes('ran never'),
    'the steps before the failing one ran, the ones after it never do', leg.log);

  // exit 3: infra for a leg the table marks so, a failure for any other
  leg = runLeg(P + 'c1');
  r = names('infra');
  t.check(leg.rc === 3 && runLeg(P + 'd1').rc === 3 && r === P + 'c1',
    'exit 3 reaches the caller, and is an infra flake only for a leg the table marks infraExit', JSON.stringify([leg.rc, r]));

  // a pass line
  t.check(runLeg(P + 'p1').rc === 0, 'a leg with a pass line passes when its log holds the line');
  t.check(runLeg(P + 'p2').rc === 1, 'a leg with a pass line FAILS (exit 1) when its log lacks it, though its steps passed');

  // a leg the table does not hold
  leg = runLeg(P + 'nosuch');
  t.check(leg.rc === 1 && new RegExp('run_leg: legs\\.js: no leg named "' + P + 'nosuch"').test(leg.log),
    'a leg the table does not hold is a hard failure (exit 1, never the infra 3), its log saying why', JSON.stringify(leg));

  // a wave that ran fewer legs than its list fails the run
  r = node('const run = C.newRun([]); run.res.push(["a", 0], ["b", 1]); C.legsAllRan(run, ["a", "b", "c"]); console.log("ok=" + run.ok + " tally=" + run.tally);');
  t.check(/ok=false tally= c:NEVER-RAN/.test(r.out), 'a leg the run named that no wave started fails the run (NEVER-RAN)', r.out + r.err);
  r = node('const run = C.newRun([]); run.res.push(["a", 0], ["b", 1]); C.legsAllRan(run, ["a", "b"]); console.log("ok=" + run.ok);');
  t.check(/ok=true/.test(r.out), 'every leg with a result: legsAllRan changes nothing', r.out + r.err);

  // the table's own rules
  const errs = (legs) => L.tableErrors(legs).join(' | ');
  const ok = { name: 'x', waves: ['A'], steps: [STEP('tests', 's.js')], headline: 'x' };
  const fourWaves = ['A', 'B', 'C', 'D'].map((w) => ({ ...ok, name: 'w' + w.toLowerCase(), waves: [w] }));
  t.check(errs(fourWaves) === '', 'a table with a leg in each wave can be run');
  t.check(/no wave and no presuite runs it/.test(errs([...fourWaves, { ...ok, name: 'idle', waves: [] }])), 'a row no wave and no presuite schedules is refused');
  t.check(/named twice/.test(errs([...fourWaves, { ...fourWaves[0] }])), 'a name twice is refused');
  t.check(/unknown place "E"/.test(errs([...fourWaves, { ...ok, name: 'e', waves: ['E'] }])), 'an unknown place is refused');
  t.check(/wave C holds no leg/.test(errs(fourWaves.filter((r) => r.name !== 'wc'))), 'a wave that holds no leg is refused');
  t.check(/a step is \{ suite \}/.test(errs([...fourWaves, { ...ok, name: 's', steps: [{ cwd: 'elsewhere', alarm: 1, script: 's.js', args: [] }] }])),
    'a step with an unknown cwd is refused');
  t.check(/unknown placeholder \{NOPE\}/.test(errs([...fourWaves, { ...ok, name: 'p', steps: [STEP('tests', 's.js', '{NOPE}')] }])), 'an unknown placeholder is refused');
  t.check(/no regular expression/.test(errs([...fourWaves, { ...ok, name: 'h', headline: '(' }])), 'a headline that is no regular expression is refused');
  t.check(/an argument is a non-empty string/.test(errs([...fourWaves, { ...ok, name: 'g', steps: [STEP('tests', 's.js', '')] }])),
    'an empty argument is refused (a tab-separated row would drop it)');
  t.check(/its passLine is a non-empty line with no tab/.test(errs([...fourWaves, { ...ok, name: 'l', passLine: 'APPS\tOK' }])), 'a tab in a pass line is refused');
  t.check(/a script is a path with no tab/.test(errs([...fourWaves, { ...ok, name: 'k', steps: [STEP('tests', 'my script.js')] }])), 'a script path with a space is refused');
  t.check(/its passLine is plain text/.test(errs([...fourWaves, { ...ok, name: 'q', passLine: 'APPS OK.' }])),
    'a pass line holding a regular-expression character is refused: fg searches the log for it as written');

  // the REAL table
  t.check(L.tableErrors().length === 0, 'the real table can be run', L.tableErrors().join(' | '));
  const tests = path.resolve(FIZZYGUM, '..', 'Fizzygum-tests');
  const missing = L.LEGS.flatMap((r) => r.steps.filter((s) => s.script).map((s) => path.join(s.cwd === 'tests' ? tests : FIZZYGUM, s.script)))
    .filter((f) => !fs.existsSync(f));
  t.check(missing.length === 0, 'every step\'s script exists', missing.join(' '));
  const { VERBS } = require('./fg-verbs');
  const verbs = L.LEGS.filter((r) => r.verb).map((r) => r.verb).filter((v) => !Object.prototype.hasOwnProperty.call(VERBS, v));
  t.check(verbs.length === 0, 'every verb a row names is a verb fg defines', verbs.join(' '));
  const commitPoint = fs.readFileSync(path.join(__dirname, 'fg-commit-point.js'), 'utf8');
  for (const use of ["require('./legs')", "tableNames('presuite'), inf = tableNames('infra')", "['gauntlet', 'infra', 'A', 'B', 'C', 'D'].map(tableNames)",
    'await runWave(run, A);', 'await runWave(run, B);', 'await runWave(run, C);', 'await runWave(run, D);', 'legsAllRan(run, all);',
    'legsAllRan(run, p.names);', 'L.legNamed(name)', 'for (const n of all) {',
    // the exit-3 rule is the table's, in the retry and in the serial path alike
    'rc2 === 3 && run.infra.has(n)', 'rc === 3 && inf.includes(n)']) {
    t.check(commitPoint.includes(use), 'fg reads its legs from the table: `' + use + '`');
  }
} finally {
  fs.rmSync(temp, { recursive: true, force: true });

}
t.done();

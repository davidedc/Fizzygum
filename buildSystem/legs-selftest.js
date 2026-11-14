#!/usr/bin/env node
'use strict';
// legs-selftest.js — the cases of the gauntlet's leg table (legs.js) and of the runner that reads it: fg's own
// `run_leg`, `legs`, `to` and `infra_leg`, taken out of the real `fg` file and run under the macOS /bin/bash fg runs
// under (3.2), on a SMALL table written beside a copy of legs.js's code, whose steps are tiny node scripts that print
// their arguments and working directory and exit as told. So it holds, end to end: the order (the gauntlet's waves A..D,
// a wave's legs in table order), a wave, a FAILING row (its first failing step ends it with that step's exit code, the
// steps after it never run), exit 3 (an INFRA flake for a leg the table marks so, a failure for any other), a pass line,
// the shard placeholders, each step's cwd, and a leg the table does not hold (a hard failure). Then the table's own rules
// (tableErrors) on broken tables, and the REAL table: it can be run, every step's script exists, every verb a row names
// is one fg defines, and fg reads every list it uses from it.
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const { cases } = require('./lib/selftest-verdict');
const L = require('./legs');

const t = cases('legs');
const FIZZYGUM = path.resolve(__dirname, '..');
const FG = path.join(FIZZYGUM, 'fg');
const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'legs-selftest-'));
const FZ = path.join(temp, 'Fizzygum'), FT = path.join(temp, 'Fizzygum-tests');
// every leg here writes /tmp/fg-<name>.log: a prefix no real leg has, and this run's own (two builds at once)
const P = 'legs-selftest-' + process.pid + '-';

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

// ---- fg's own functions, out of the real file: a one-line function, or one closed by `}` alone on a line
const fgText = fs.readFileSync(FG, 'utf8');
function fgFunction(name) {
  const m = new RegExp('(^|\\n)(' + name + '\\(\\)\\{[^\\n]*)').exec(fgText);
  if (!m) return undefined;
  if (/\}\s*(#.*)?$/.test(m[2])) return m[2];
  const from = m.index + m[1].length, close = fgText.indexOf('\n}\n', from);
  return fgText.slice(from, close + 2);
}
const FUNCS = ['to', 'legs', 'leg_list_ok', 'infra_leg', 'run_leg'].map((n) => [n, fgFunction(n)]);
for (const [n, f] of FUNCS) t.check(!!f, 'fg defines ' + n + '()');
// a stand-in fg_suite (the real one runs the suite) and verdict_end, recording what they were given
const PRELUDE = 'set -u\nFZ=' + JSON.stringify(FZ) + '\nFT=' + JSON.stringify(FT) + '\n' +
  'fg_suite(){ echo "fg_suite $*"; }\nverdict_end(){ :; }\n' + FUNCS.map(([, f]) => f).join('\n') + '\n';
function bash(script) {
  const r = spawnSync('/bin/bash', ['-c', PRELUDE + script], { encoding: 'utf8', env: { PATH: process.env.PATH, HOME: process.env.HOME } });
  return { status: r.status, out: r.stdout.trim(), err: r.stderr.trim() };
}
const logOf = (name) => { try { return fs.readFileSync('/tmp/fg-' + name + '.log', 'utf8'); } catch (e) { return ''; } };
const runLeg = (name, env = '') => {
  const r = bash(env + 'run_leg ' + name + '; echo "rc=$?"');
  return { rc: Number((/rc=(\d+)/.exec(r.out) || [])[1]), log: logOf(name), err: r.err };
};

try {
  // the order, a wave, the presuite
  let r = bash('legs names gauntlet');
  t.check(r.out === [P + 'a1', P + 'a2', P + 'b1', P + 'c1', P + 'd1'].join(' '), 'the gauntlet\'s legs: wave by wave, A..D, each in table order', r.out + r.err);
  r = bash('legs names A');
  t.check(r.out === P + 'a1 ' + P + 'a2', 'a wave\'s legs', r.out);
  r = bash('legs names presuite');
  t.check(r.out === [P + 'a2', P + 'p1', P + 'p2'].join(' '), 'the presuite\'s legs, in table order', r.out);
  r = bash('legs names nowhere');
  t.check(r.status === 2 && /no place "nowhere"/.test(r.err), 'an unknown place: exit 2, saying why', JSON.stringify(r));

  // a passing row: each step in its own cwd, the placeholders the caller's shard counts, the log appended step by step
  let leg = runLeg(P + 'a1', 'FG_GATE_SHARDS=4; ');
  t.check(leg.rc === 0, 'a row whose steps pass passes', JSON.stringify(leg));
  t.check(leg.log.includes('ran one in ' + fs.realpathSync(FT)) && leg.log.includes('ran 4 in ' + fs.realpathSync(FZ)),
    'each step runs in its cwd (tests / fizzygum), the {GATE_SHARDS} placeholder the caller\'s FG_GATE_SHARDS', leg.log);
  t.check(new RegExp('fg-leg: ' + P + 'a1 rc=0 \\d+s').test(leg.log), 'the leg log ends with fg\'s `fg-leg:` stamp', leg.log);
  leg = runLeg(P + 'a1');
  t.check(leg.log.includes('ran 6 in '), '{GATE_SHARDS} defaults to 6', leg.log);
  leg = runLeg(P + 'a2', 'FG_SUITE_SHARDS=8; ');
  t.check(leg.rc === 0 && leg.log.includes('fg_suite --dpr=2 --shards=8'), 'a suite step is fg_suite with its flags, {SUITE_SHARDS} the caller\'s', leg.log);
  leg = runLeg(P + 'a2');
  t.check(leg.log.includes('fg_suite --dpr=2 --shards=4'), '{SUITE_SHARDS} defaults to 4', leg.log);

  // a failing row: its first failing step ends it, with that step's exit code
  leg = runLeg(P + 'b1');
  t.check(leg.rc === 5, 'a failing step ends the leg with ITS exit code', JSON.stringify(leg.rc));
  t.check(leg.log.includes('ran first') && leg.log.includes('exiting 5') && !leg.log.includes('ran never'),
    'the steps before the failing one ran, the ones after it never do', leg.log);

  // exit 3: infra for a leg the table marks so, a failure for any other
  leg = runLeg(P + 'c1');
  r = bash('INFRA_LEGS=$(legs names infra); infra_leg ' + P + 'c1 && echo infra; infra_leg ' + P + 'd1 && echo infra2; echo done');
  t.check(leg.rc === 3 && r.out === 'infra\ndone', 'exit 3 reaches the caller, and is an infra flake only for a leg the table marks infraExit', JSON.stringify([leg.rc, r.out]));

  // a pass line
  t.check(runLeg(P + 'p1').rc === 0, 'a leg with a pass line passes when its log holds the line');
  t.check(runLeg(P + 'p2').rc === 1, 'a leg with a pass line FAILS (exit 1) when its log lacks it, though its steps passed');

  // a leg the table does not hold
  leg = runLeg(P + 'nosuch');
  t.check(leg.rc === 1 && new RegExp('run_leg: legs\\.js: no leg named "' + P + 'nosuch"').test(leg.log),
    'a leg the table does not hold is a hard failure (exit 1, never the infra 3), its log saying why', JSON.stringify(leg));

  // a reader whose answer is not a row: the leg FAILS, never runs less than its row
  r = bash('legs(){ printf "census stand-in: node buildSystem/legs.js\\n"; }; run_leg ' + P + 'a1; echo "rc=$?"');
  t.check(/rc=1/.test(r.out) && /cannot read: census stand-in/.test(logOf(P + 'a1')), 'a row line run_leg cannot read fails the leg (exit 1)', r.out + logOf(P + 'a1'));
  r = bash('legs(){ ( cd "$FZ" && node buildSystem/legs.js --shell "$@"; echo "a warning on stderr" >&2 ); }; run_leg ' + P + 'a1; echo "rc=$?"');
  t.check(/rc=0/.test(r.out) && !/a warning/.test(logOf(P + 'a1')), 'the reader\'s stderr is no part of the row: a warning beside a good answer leaves the leg passing', r.out + logOf(P + 'a1'));
  r = bash('legs(){ printf "passline\\tX\\n"; }; run_leg ' + P + 'a1; echo "rc=$?"');
  t.check(/rc=1/.test(r.out) && /gave no step/.test(logOf(P + 'a1')), 'a row with no step fails the leg (exit 1)', r.out + logOf(P + 'a1'));
  r = bash('leg_list_ok "dpr1 dpr2 tier-naming" && echo ok1; leg_list_ok "" || echo empty; leg_list_ok "census stand-in: node buildSystem/legs.js" || echo junk');
  t.check(r.out === 'ok1\nempty\njunk', 'a leg list holds at least one leg and nothing but leg names (fg refuses anything else)', r.out);

  // a wave that ran fewer legs than its list fails the run
  r = bash(fgFunction('legs_all_ran') + '\nWAVE_RES=" a=0 b=1"; tally=""; ok=1; legs_all_ran a b c; echo "ok=$ok tally=$tally"');
  t.check(/ok=0 tally= c:NEVER-RAN/.test(r.out), 'a leg the run named that no wave started fails the run (NEVER-RAN)', r.out + r.err);
  r = bash(fgFunction('legs_all_ran') + '\nWAVE_RES=" a=0 b=1"; tally=""; ok=1; legs_all_ran a b; echo "ok=$ok"');
  t.check(/ok=1/.test(r.out), 'every leg with a result: legs_all_ran changes nothing', r.out + r.err);

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

  // the REAL table
  t.check(L.tableErrors().length === 0, 'the real table can be run', L.tableErrors().join(' | '));
  const tests = path.resolve(FIZZYGUM, '..', 'Fizzygum-tests');
  const missing = L.LEGS.flatMap((r) => r.steps.filter((s) => s.script).map((s) => path.join(s.cwd === 'tests' ? tests : FIZZYGUM, s.script)))
    .filter((f) => !fs.existsSync(f));
  t.check(missing.length === 0, 'every step\'s script exists', missing.join(' '));
  const verbs = L.LEGS.filter((r) => r.verb).map((r) => r.verb).filter((v) => !new RegExp('\\n  ' + v.replace(/-/g, '\\-') + '\\)').test(fgText));
  t.check(verbs.length === 0, 'every verb a row names is a verb fg defines', verbs.join(' '));
  for (const use of ['legs names gauntlet', 'legs names infra', 'legs names presuite', 'leg_list_ok "$GAUNTLET_LEGS"', 'leg_list_ok "$PRESUITE_LEGS"',
    'WAVE_A=$(legs names A)', 'WAVE_B=$(legs names B)', 'WAVE_C=$(legs names C)', 'WAVE_D=$(legs names D)',
    'leg_list_ok "$WAVE_A"', 'leg_list_ok "$WAVE_B"', 'leg_list_ok "$WAVE_C"', 'leg_list_ok "$WAVE_D"',
    'run_wave $WAVE_A', 'run_wave $WAVE_B', 'run_wave $WAVE_C', 'run_wave $WAVE_D', 'legs_all_ran $GAUNTLET_LEGS', 'legs_all_ran $PRESUITE_LEGS',
    'legs row "$name"', 'legs headline "$1"', 'legs roster', 'for n in $GAUNTLET_LEGS; do',
    // the exit-3 rule is the table's, in the retry and in the serial path alike
    'if [ "$rc2" -eq 3 ] && infra_leg "$n"; then', 'elif [ $rc -eq 3 ] && infra_leg "$n"; then']) {
    t.check(fgText.includes(use), 'fg reads its legs from the table: `' + use + '`');
  }
} finally {
  fs.rmSync(temp, { recursive: true, force: true });
  for (const f of fs.readdirSync('/tmp')) if (f.startsWith('fg-' + P)) fs.rmSync(path.join('/tmp', f), { recursive: true, force: true });
}
t.done();

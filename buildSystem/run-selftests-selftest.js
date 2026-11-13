'use strict';
// run-selftests-selftest.js — the self-test runner's own two decisions, on canned input: the verdict it gives one run
// (judge), and whether a script's code offers a self-test outside the convention (offeredFlags). Its ship gate is the
// direction that matters for a runner: no run that did not PROVE a pass reads as a pass — a non-zero exit, a FAIL
// verdict, no verdict, a verdict that is not the last line, zero cases — and prose or an echo that merely NAMES a
// self-test flag is not code offering one. Run by run-selftests.js itself, with every other self-test.

const path = require('path');
const { judge, offeredFlags, undiscovered, longestFirst } = require('./run-selftests');
const t = require('./lib/selftest-verdict').cases('run-selftests');

const RUNS = [
  // [what, run, expected token (undefined = pass)]
  ['a pass: exit 0, the PASS verdict last, N cases', { status: 0, stdout: '  ok   x\n[x] SELFTEST PASS — 3 cases\n' }, undefined],
  ['one case is a case', { status: 0, stdout: '[x] SELFTEST PASS — 1 case\n' }, undefined],
  ['exit 1 with a PASS verdict', { status: 1, stdout: '[x] SELFTEST PASS — 3 cases\n' }, 'SELFTEST_FAILED'],
  ['exit 0 with a FAIL verdict', { status: 0, stdout: '[x] SELFTEST FAIL — 1 of 3 cases\n' }, 'SELFTEST_FAILED'],
  ['killed by a signal (status null)', { status: null, stdout: '[x] SELFTEST PASS — 3 cases\n' }, 'SELFTEST_FAILED'],
  ['a spawn error', { status: 0, error: new Error('ETIMEDOUT'), stdout: '[x] SELFTEST PASS — 3 cases\n' }, 'SELFTEST_FAILED'],
  ['exit 0, nothing printed', { status: 0, stdout: '' }, 'SELFTEST_NO_VERDICT'],
  ['exit 0, an old-style "OK" line', { status: 0, stdout: 'gate-tokens-selftest OK\n' }, 'SELFTEST_NO_VERDICT'],
  ['exit 0, the verdict not on the last line', { status: 0, stdout: '[x] SELFTEST PASS — 3 cases\nmore output\n' }, 'SELFTEST_NO_VERDICT'],
  ['exit 0, zero cases', { status: 0, stdout: '[x] SELFTEST PASS — 0 cases\n' }, 'SELFTEST_VACUOUS'],
];
for (const [what, run, want] of RUNS) {
  const got = judge(run).token;
  t.check(got === want, `judge: ${what} -> ${got || 'pass'}`, `expected ${want || 'pass'}`);
}

const FLAGS = [
  // [what, ext, text, expected number of offers]
  ['JS: an argv flag check', '.js', "if (argv.includes('--selftest')) run();", 1],
  ['JS: the hyphenated spelling in a KNOWN list', '.js', "const KNOWN = ['--test', '--self-test'];", 1],
  ['JS: an environment switch', '.js', 'if (process.env.CACHE_ORACLE_SELFTEST) plant();', 1],
  ['JS: a comment naming the flag', '.js', '// run it with --self-test\nconst x = 1;', 0],
  ['JS: a message naming the flag among other words', '.js', "console.log('see the --selftest mode');", 0],
  ['JS: a -selftest.js file name', '.js', "require('./png-selftest.js');", 0],
  ['shell: a flag on a code line', '.sh', 'node scripts/x.js --self-test', 1],
  ['shell: an environment switch assigned', '.sh', 'X_SELFTEST=1 bash run-gate.sh', 1],
  ['shell: an environment switch expanded', '.sh', 'if [ "${CACHE_ORACLE_SELFTEST:-0}" = 1 ]; then :; fi', 1],
  ['shell: a comment naming the flag', '.sh', '# pass --selftest to prove it', 0],
  ['shell: a word in an echo', '.sh', 'echo "SELFTEST OK"', 0],
  ['JS: a flag with a value', '.js', "if (argv.includes('--selftest=1')) run();", 1],
  ['JS: a lib/cli.js flag reader asking for one', '.js', "const plant = flagValue(argv, 'self-test');", 1],
  ['JS: a makeFlag reader asking for one', '.js', "const go = makeFlag(argv)('selftest');", 1],
  ['JS: a bracketed environment switch', '.js', "if (process.env['FOO_SELFTEST']) plant();", 1],
  ['JS: a destructured environment switch', '.js', 'const { FOO_SELFTEST } = process.env;', 1],
  ['JS: the convention kind passed to discover()', '.js', "const tests = discover('selftest');", 0],
  ['shell: a flag inside an echo', '.sh', 'echo "pass --selftest to prove it"', 0],
  ['Python: a flag literal', '.py', "if '--selftest' in sys.argv: run()", 1],
  ['Python: a comment naming the flag', '.py', '# pass --selftest to prove it', 0],
  ['another extension offers nothing', '.coffee', "x = '--selftest'", 0],
];
for (const [what, ext, text, want] of FLAGS) {
  const got = offeredFlags(text, ext).length;
  t.check(got === want, `offeredFlags: ${what} -> ${got}`, `expected ${want}`);
}

const root = '/r';
const files = ['buildSystem/a-selftest.js', 'buildSystem/b.selftest.js', 'scripts/c-self-test.js', 'docs/d-selftest.js',
  'scripts/e_selftest.mjs', 'buildSystem/plain.js'].map((f) => path.join(root, f));
const stray = undiscovered(files, new Set([files[0]])).map((f) => path.relative(root, f)).join(',');
t.check(stray === 'buildSystem/b.selftest.js,scripts/c-self-test.js,docs/d-selftest.js,scripts/e_selftest.mjs',
  `undiscovered: misnamed, misplaced and wrong-extension self-tests are reported, a discovered one and a plain file are not -> ${stray}`);
t.check(undiscovered([require.resolve('./run-selftests'), require.resolve('./lib/selftest-verdict')], new Set()).length === 0,
  'undiscovered: the runner and the verdict lib are the machinery, not self-tests');

// ---- the REAL runner on a planted miniature workspace (--umbrella=) -------------------------------------------------
// The cases above judge outputs and texts in memory; here the runner itself — discovery through lib/what-runs.js, the
// pool, the verdict reading, the two hiding rules, the exit — runs over a workspace written in tmp at run time (a
// committed fixture named like a self-test would itself fail the real build). The self-test switch is assembled, so
// this file never holds the literal it refuses.
const { proveGate } = require('./lib/planted-src');
const SWITCH = '--self' + 'test';
const verdict = (name, line) => `console.log(${JSON.stringify(`[${name}] SELFTEST ${line}`)});\n`;
const BS = 'Fizzygum/buildSystem/';
// the pool's start order: a file with no recorded time first, then longest first, ties in discovery order
{
  const order = longestFirst(['a', 'b', 'c', 'd', 'e'], { a: 1, b: 5, d: 3, e: 3 });
  t.check(order.join() === '2,1,3,4,0', 'longestFirst: the unrecorded file, then the longest; a tie keeps discovery order', order.join());
  t.check(longestFirst(['a', 'b'], {}).join() === '0,1', 'longestFirst: no record at all is discovery order');
}

// the gate census's fixtures: a build that launches gates, a gate that names its rules, and a proof — a self-test that
// launches a gate through a proof helper it requires and calls, in code that never runs (the miniature has no lib/)
const registryGate = "const rules = require('./lib/gate-rules').forGate(__filename);\n";
const proofOf = (gate, name, call = true) => "const path = require('path');\n" +
  `const GATE = path.join(__dirname, '${gate}');\n` +
  `if (false) { const { proveGate } = require('./lib/planted-src');${call ? ' proveGate({ gate: GATE });' : ''} }\n` +
  verdict(name, 'PASS — 1 case');
// a workspace's fg, whose four leg functions the gate census reads (lib/what-runs.js): here they launch nothing
const FG_LAUNCHING_NOTHING = 'fg_build(){\n  :\n}\nfg_suite(){ :; }\nrun_lint(){\n  :\n}\nrun_leg(){\n  :\n}\n';

proveGate({
  name: 'run-selftests',
  cases: t,
  gate: path.join(__dirname, 'run-selftests.js'),
  from: null,
  rail: '--umbrella=',
  pass: /^\[selftests\] OK — 1 self-test\(s\), 1 cases, /m,
  control: {
    plants: {
      'Fizzygum/build_it_please.sh': 'node buildSystem/g-gate.js\n',
      'Fizzygum/fg': FG_LAUNCHING_NOTHING,
      // a gate that builds its own self-test's path (to skip it) reads as launching it: a self-test is still no gate
      [BS + 'g-gate.js']: registryGate + "const path = require('path');\nconst SELF = path.join(__dirname, 'g-gate-selftest.js');\n",
      [BS + 'g-gate-selftest.js']: proofOf('g-gate.js', 'g-gate'),
      [BS + 'mentions.js']: `// a comment may name ${SWITCH}; code may not offer it\n`,
      'Fizzygum-tests/tests/SystemTest_x/named-like.selftest.js': '// test content, not a script\n',
    },
  },
  runs: [{
    label: 'a failing, a silent and a vacuous self-test; a switch offered; a misnamed self-test',
    plants: {
      [BS + 'p-selftest.js']: verdict('p', 'PASS — 1 case'),
      [BS + 'f-selftest.js']: verdict('f', 'FAIL — 1 of 1 case') + 'process.exitCode = 1;\n',
      [BS + 'n-selftest.js']: '// says nothing\n',
      [BS + 'v-selftest.js']: verdict('v', 'PASS — 0 cases'),
      [BS + 'offers.js']: `const flag = '${SWITCH}';\n`,
      [BS + 'm.selftest.js']: verdict('m', 'PASS — 1 case'),
    },
    expect: {
      SELFTEST_FAILED: /^  SELFTEST_FAILED  Fizzygum\/buildSystem\/f-selftest\.js  \(exit 1, /m,
      SELFTEST_NO_VERDICT: /^  SELFTEST_NO_VERDICT  Fizzygum\/buildSystem\/n-selftest\.js  \(exit 0, /m,
      SELFTEST_VACUOUS: /^  SELFTEST_VACUOUS  Fizzygum\/buildSystem\/v-selftest\.js  \(exit 0, /m,
      SELFTEST_OUTSIDE_CONVENTION: /^  SELFTEST_OUTSIDE_CONVENTION  Fizzygum\/buildSystem\/offers\.js:1  /m,
      SELFTEST_UNDISCOVERED: /^  SELFTEST_UNDISCOVERED  Fizzygum\/buildSystem\/m\.selftest\.js$/m,
    },
    absent: [/mentions\.js|named-like/],
  }, {
    label: 'the headless tier',
    args: ['--headless'],
    plants: { [BS + 'h-selftest-headless.js']: verdict('h', 'FAIL — 1 of 1 case') + 'process.exitCode = 1;\n' },
    expect: { SELFTEST_FAILED: /^  SELFTEST_FAILED  Fizzygum\/buildSystem\/h-selftest-headless\.js  \(exit 1, /m },
  }, {
    label: 'the gate census: a gate no proof launches, a gate that names no rule, a build step that says so, a proof that ' +
      'never calls its helper, a not-a-gate line below the header, a gate reached only as a row of the build\'s gate table',
    plants: {
      'Fizzygum/build_it_please.sh': ['noproof-gate', 'noreg-gate', 'step', 'callless-gate', 'late-gate']
        .map((g) => `node buildSystem/${g}.js\n`).join('')
        + 'node ./buildSystem/run-gates.js --noSyntaxCheck=false --shipsTests=true -- "${args[@]}"\n',
      'Fizzygum/fg': FG_LAUNCHING_NOTHING,
      // the runner says why it is no gate; its table's one row names a script no text scan can read, so only the
      // table, read as data, makes it a gate
      [BS + 'run-gates.js']: "#!/usr/bin/env node\n'use strict';\n// not-a-gate: the runner of the table's gates\nrequire('./gates');\n",
      [BS + 'gates.js']: "const path = require('path');\nmodule.exports = { BUILD_ARGS: 'BUILD_ARGS', GATES: [{ script: " +
        "path.join(__dirname, ['table', 'gate'].join('-') + '.js'), args: [], when: 'checked', banner: 'b', failure: 'f' }] };\n",
      [BS + 'table-gate.js']: "console.log('no registry');\n",
      [BS + 'noproof-gate.js']: registryGate,
      [BS + 'noreg-gate.js']: "console.log('no registry');\n",
      [BS + 'noreg-gate-selftest.js']: proofOf('noreg-gate.js', 'noreg-gate'),
      [BS + 'step.js']: "#!/usr/bin/env node\n'use strict';\n// not-a-gate: a build step, writing what the gates read\nconsole.log('x');\n",
      [BS + 'callless-gate.js']: registryGate,
      [BS + 'callless-gate-selftest.js']: proofOf('callless-gate.js', 'callless-gate', false),
      [BS + 'late-gate.js']: registryGate + '// not-a-gate: below the code, so it states nothing about the file\n',
    },
    expect: {
      GATE_WITHOUT_PROOF: /^  GATE_WITHOUT_PROOF  Fizzygum\/buildSystem\/noproof-gate\.js$/m,
      GATE_WITHOUT_REGISTRY: /^  GATE_WITHOUT_REGISTRY  Fizzygum\/buildSystem\/noreg-gate\.js$/m,
    },
    lines: [/^  GATE_WITHOUT_PROOF  Fizzygum\/buildSystem\/callless-gate\.js$/m,
            /^  GATE_WITHOUT_PROOF  Fizzygum\/buildSystem\/late-gate\.js$/m,
            /^  GATE_WITHOUT_REGISTRY  Fizzygum\/buildSystem\/table-gate\.js$/m],
    absent: [/step\.js/],
  }],
});

t.done();

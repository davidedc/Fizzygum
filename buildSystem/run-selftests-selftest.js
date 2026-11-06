'use strict';
// run-selftests-selftest.js — the self-test runner's own two decisions, on canned input: the verdict it gives one run
// (judge), and whether a script's code offers a self-test outside the convention (offeredFlags). Its ship gate is the
// direction that matters for a runner: no run that did not PROVE a pass reads as a pass — a non-zero exit, a FAIL
// verdict, no verdict, a verdict that is not the last line, zero cases — and prose or an echo that merely NAMES a
// self-test flag is not code offering one. Run by run-selftests.js itself, with every other self-test.

const path = require('path');
const { judge, offeredFlags, undiscovered } = require('./run-selftests');
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

t.done();

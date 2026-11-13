'use strict';
// run-gates-selftest.js — run-gates.js's runner on a table of its own: the rows run in order, a row whose WHEN does not
// hold is passed over, the first failure rings the bell, prints its line on stderr and stops the run with exit 1, an OK
// line is printed only where a row has one, a BUILD_ARGS row gets the build's arguments, and a row naming a WHEN the
// runner does not know stops the run before any row runs, under --noSyntaxCheck too; and on the real gates.js: every
// row names a known WHEN and a script that exists, once, a row whose script lives in the tests repo runs only where
// that repo is present, and the lint index (docs/architecture/lint-and-static-checks.md) names each gate at its row. The command line is seen refusing a malformed invocation (exit 2), refusing a malformed
// table (exit 2, a planted copy of the runner beside a table of its own) and, under --noSyntaxCheck=true, running
// nothing (exit 0). Run by buildSystem/run-selftests.js on every build.
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const { runGates, tableErrorOf } = require('./run-gates');
const { GATES, WHEN, BUILD_ARGS, TESTS_REPO } = require('./gates');
const t = require('./lib/selftest-verdict').cases('run-gates');

// a recording io: what was printed where, which scripts ran with which args, how often the bell rang
function recorder(failing = new Set()) {
  const log = [];
  return {
    log,
    out: (text) => log.push(['out', text]),
    err: (text) => log.push(['err', text]),
    run: (script, args) => { log.push(['run', script, args.join(' ')]); return failing.has(script) ? 3 : 0; },
    bell: () => log.push(['bell']),
  };
}
const row = (script, when, ok, args = []) => ({ script, args, when, banner: `B ${script}`, failure: `F ${script}`, ok });
const TABLE = [
  row('a', 'checked', 'OK a'),
  row('b', 'testsShipped', 'OK b'),
  row('c', 'testsRepo', undefined),
  row('d', 'checked', 'OK d', BUILD_ARGS),
  row('e', 'checked', 'OK e'),
];
const ctx = (over) => ({ noSyntaxCheck: false, shipsTests: true, testsRepoPresent: true, buildArgs: ['--profile', 'lean'], ...over });
const ran = (io) => io.log.filter((e) => e[0] === 'run').map((e) => e[1]).join('');

{ // every row, in order, each banner before its run and its OK after
  const io = recorder();
  const code = runGates(TABLE, ctx(), io);
  t.check(code === 0 && ran(io) === 'abcde', 'every row runs, in order, exit 0', `exit ${code}, ran ${ran(io)}`);
  const want = [['out', 'B a\n'], ['run', 'a', ''], ['out', 'OK a\n'], ['out', 'B b\n'], ['run', 'b', ''], ['out', 'OK b\n'],
    ['out', 'B c\n'], ['run', 'c', ''], ['out', 'B d\n'], ['run', 'd', '--profile lean'], ['out', 'OK d\n'],
    ['out', 'B e\n'], ['run', 'e', ''], ['out', 'OK e\n']];
  t.check(JSON.stringify(io.log) === JSON.stringify(want), 'banner, run, OK in order; a row with no OK prints none; BUILD_ARGS forwarded',
    JSON.stringify(io.log));
}
{ // WHEN: the tests repo absent drops b and c; the tests not shipped drops b; --noSyntaxCheck drops everything
  const io1 = recorder(); runGates(TABLE, ctx({ testsRepoPresent: false }), io1);
  t.check(ran(io1) === 'ade', 'no tests repo: the testsShipped and testsRepo rows are passed over', ran(io1));
  const io2 = recorder(); runGates(TABLE, ctx({ shipsTests: false }), io2);
  t.check(ran(io2) === 'acde', 'tests not shipped: the testsShipped row is passed over, the testsRepo row runs', ran(io2));
  const io3 = recorder(); const code3 = runGates(TABLE, ctx({ noSyntaxCheck: true }), io3);
  t.check(code3 === 0 && io3.log.length === 0, '--noSyntaxCheck: nothing runs, nothing is printed, exit 0', JSON.stringify(io3.log));
}
{ // the first failure: bell, its line on stderr, exit 1, and no later row runs
  const io = recorder(new Set(['c']));
  const code = runGates(TABLE, ctx(), io);
  const tail = io.log.slice(-3);
  t.check(code === 1 && ran(io) === 'abc', 'a failing row stops the run with exit 1', `exit ${code}, ran ${ran(io)}`);
  t.check(JSON.stringify(tail) === JSON.stringify([['run', 'c', ''], ['bell'], ['err', 'F c\n']]),
    'the failure rings the bell, then prints its line on stderr, and prints no OK', JSON.stringify(tail));
}
{ // an unknown WHEN is a table error, never a silent skip: nothing runs, whatever the flags
  const BAD = [...TABLE, row('z', 'sometimes', 'OK z')];
  for (const [over, what] of [[{}, 'a checked build'], [{ noSyntaxCheck: true }, '--noSyntaxCheck']]) {
    const io = recorder();
    let threw;
    try { runGates(BAD, ctx(over), io); } catch (e) { threw = e.message; }
    t.check(threw !== undefined && /z names an unknown when 'sometimes'/.test(threw) && io.log.length === 0,
      `a later row naming an unknown WHEN stops the run before any row runs (${what})`, `${threw} / ${JSON.stringify(io.log)}`);
  }
  t.check(tableErrorOf(TABLE) === undefined, 'a well-formed table has no table error');
}
{ // the real table
  t.check(GATES.length > 0 && tableErrorOf(GATES) === undefined, 'gates.js has rows, each naming a known WHEN', tableErrorOf(GATES));
  // the tests repo's scripts exist only where it is checked out, which is exactly where their rows run
  // TESTS_REPO is where the build names the tests repo everywhere else (`../Fizzygum-tests` beside Fizzygum/): a
  // wrong path would make the runner read the repo as absent and pass five gates over, saying nothing
  t.check(TESTS_REPO === path.resolve(__dirname, '..', '..', 'Fizzygum-tests'),
    'gates.js TESTS_REPO is the Fizzygum-tests directory beside this repo', String(TESTS_REPO));
  const inTestsRepo = (r) => r.script.startsWith(TESTS_REPO + path.sep);
  t.check(GATES.filter(inTestsRepo).every((r) => r.when === 'testsShipped' || r.when === 'testsRepo'),
    'every row whose script lives in the tests repo runs only where that repo is present',
    GATES.filter((r) => inTestsRepo(r) && r.when === 'checked').map((r) => r.script).join(', '));
  const testsRepoPresent = fs.existsSync(TESTS_REPO);
  const missing = GATES.filter((r) => (testsRepoPresent || !inTestsRepo(r)) && !fs.existsSync(r.script));
  t.check(missing.length === 0, `every gates.js row names a script that exists${testsRepoPresent ? '' : ' (the tests repo is absent: its rows not looked up)'}`,
    missing.map((r) => r.script).join(', '));
  t.check(new Set(GATES.map((r) => r.script)).size === GATES.length, 'no gates.js script is run twice');
  // the lint index's gate inventory names each gate's row of this table ("Wired": `row N`) — a position, so a row
  // inserted or moved renumbers every later one: held here, it fails until the index says where each gate now runs
  const index = fs.readFileSync(path.join(__dirname, '..', 'docs', 'architecture', 'lint-and-static-checks.md'), 'utf8');
  const cells = [];
  for (const line of index.split('\n')) {
    const cols = line.split('|').map((c) => c.trim());
    // the File cell is a code span: the script, then any arguments it is run with
    const file = cols.length > 4 && /`([^`\s]+\.js)(?:\s[^`]*)?`/.exec(cols[2]), wired = cols.length > 4 && /^\**row (\d+)\b/.exec(cols[3]);
    if (file && wired) cells.push({ file: file[1], row: Number(wired[1]) });
  }
  const misnamed = GATES.map((r, i) => {
    const named = cells.filter((c) => c.row === i + 1);
    return named.length === 1 && r.script.endsWith(path.sep + named[0].file) ? undefined
      : `row ${i + 1} (${path.basename(r.script)}) is named by ${named.map((c) => c.file).join(', ') || 'no cell'}`;
  }).filter(Boolean);
  t.check(misnamed.length === 0 && cells.length === GATES.length, 'the lint index names every gate at its row, once',
    misnamed.join('; ') || `${cells.length} row cells for ${GATES.length} rows`);
  t.check(GATES.every((r) => r.args === BUILD_ARGS || Array.isArray(r.args)), 'every row\'s args are a list or BUILD_ARGS');
  t.check(GATES.every((r) => typeof r.banner === 'string' && typeof r.failure === 'string' && (r.ok === undefined || typeof r.ok === 'string')),
    'every row has a banner and a failure line');
}
{ // the command line
  const cli = (args) => spawnSync(process.execPath, [path.join(__dirname, 'run-gates.js'), ...args], { encoding: 'utf8', cwd: path.join(__dirname, '..') });
  const bad = cli(['--noSyntaxCheck=maybe', '--shipsTests=true', '--']);
  t.check(bad.status === 2 && /^usage: /.test(bad.stderr), 'a malformed command line is refused with exit 2', `exit ${bad.status}: ${bad.stderr}`);
  const none = cli(['--noSyntaxCheck=true', '--shipsTests=true', '--', '--profile', 'dev']);
  t.check(none.status === 0 && none.stdout === '' && none.stderr === '', '--noSyntaxCheck=true runs nothing, exit 0',
    `exit ${none.status}, out ${JSON.stringify(none.stdout)}, err ${JSON.stringify(none.stderr)}`);
  // a malformed table: the real runner, copied beside a table of its own whose second row names an unknown WHEN
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'run-gates-selftest-'));
  try {
    fs.copyFileSync(path.join(__dirname, 'run-gates.js'), path.join(dir, 'run-gates.js'));
    const gate = (name, when) => `{ script: ${JSON.stringify(path.join(dir, name))}, args: [], when: '${when}', banner: 'B ${name}', failure: 'F ${name}' }`;
    fs.writeFileSync(path.join(dir, 'a.js'), '');
    fs.writeFileSync(path.join(dir, 'gates.js'), `module.exports = { WHEN: ${JSON.stringify(WHEN)}, BUILD_ARGS: 'BUILD_ARGS',\n`
      + `  GATES: [${gate('a.js', 'checked')}, ${gate('a.js', 'often')}] };\n`);
    for (const nsc of ['false', 'true']) {
      const r = spawnSync(process.execPath, [path.join(dir, 'run-gates.js'), `--noSyntaxCheck=${nsc}`, '--shipsTests=true', '--'],
        { encoding: 'utf8', cwd: dir });
      t.check(r.status === 2 && r.stdout === '' && /a\.js names an unknown when 'often'/.test(r.stderr),
        `a malformed table is refused with exit 2 before any row runs (--noSyntaxCheck=${nsc})`,
        `exit ${r.status}, out ${JSON.stringify(r.stdout)}, err ${JSON.stringify(r.stderr)}`);
    }
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}
t.done();

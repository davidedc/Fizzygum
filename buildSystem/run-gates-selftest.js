'use strict';
// run-gates-selftest.js — run-gates.js's runner on a table of its own. The first row runs FIRST and ALONE (no other row
// starts before it has ended, and its failure stops everything); the rest run side by side, at most the pool at once,
// and are REPORTED in table order — banner, captured output, OK line — whichever finishes first; a row whose WHEN does
// not hold is passed over; the first failing row (in table order) prints its banner and output, rings the bell, prints
// its failure line on stderr, stops the rows still running and ends the run with exit 1, nothing after it printed; an
// OK line is printed only where a row has one; a BUILD_ARGS row gets the build's arguments; and a row naming a WHEN the
// runner does not know stops the run before any row runs, under --noSyntaxCheck too. On the real gates.js: every row
// names a known WHEN and a script that exists, once, and the lint index (docs/architecture/lint-and-static-checks.md)
// names each gate at its row. The command line is seen refusing a malformed invocation (exit 2), refusing a malformed
// table (exit 2) and, under --noSyntaxCheck=true, running nothing (exit 0); and, with a planted copy of the runner
// beside a table of its own, running real processes: rows finishing out of order report in order, a row's stdout and
// stderr arrive as one stream, and a failing row ends the report, its failure on stderr, exit 1. Run by
// buildSystem/run-selftests.js on every build.
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const { runGates, tableErrorOf } = require('./run-gates');
const { GATES, WHEN, BUILD_ARGS, TESTS_REPO } = require('./gates');
const t = require('./lib/selftest-verdict').cases('run-gates');

// a recording io: what was printed where, which rows ran alone or were started (with which args), when each ended or
// was stopped, and how many ran at once at most. A started row ends after delays[script] ms with `out <script>\n` as
// its output, failing (status 3) when it is in `failing`.
function recorder({ failing = new Set(), delays = {}, unstartable = new Set(), outThrowsOn } = {}) {
  const log = [];
  let running = 0, most = 0;
  return {
    log,
    most: () => most,
    out: (text) => { if (text === outThrowsOn) throw new Error('EPIPE (planted)'); log.push(['out', text]); },
    err: (text) => log.push(['err', text]),
    bell: () => log.push(['bell']),
    runAlone: (script, args) => { log.push(['alone', script, args.join(' ')]); return failing.has(script) ? 3 : 0; },
    start: (script, args) => {
      if (unstartable.has(script)) throw new Error('EMFILE (planted)');
      log.push(['start', script, args.join(' ')]);
      running++; most = Math.max(most, running);
      let done = false, finish;
      const finished = new Promise((resolve) => { finish = resolve; });
      const end = (what, result) => { if (done) return; done = true; running--; log.push([what, script]); finish(result); };
      const timer = setTimeout(() => end('end', { status: failing.has(script) ? 3 : 0, output: `out ${script}\n` }), delays[script] || 0);
      return { finished, stop: () => { clearTimeout(timer); end('stopped', { status: 1, output: '' }); } };
    },
  };
}
const row = (script, when, ok, args = []) => ({ script, args, when, banner: `B ${script}`, failure: `F ${script}`, ok });
const TABLE = [
  row('a', 'checked', 'OK a'),
  row('b', 'testsShipped', 'OK b'),
  row('c', 'checked', undefined),
  row('d', 'checked', 'OK d', BUILD_ARGS),
  row('e', 'checked', 'OK e'),
];
const ctx = (over) => ({ noSyntaxCheck: false, shipsTests: true, buildArgs: ['--profile', 'lean'], ...over });
const printed = (io) => io.log.filter((e) => e[0] === 'out' || e[0] === 'err' || e[0] === 'bell');
const kinds = (io, kind) => io.log.filter((e) => e[0] === kind).map((e) => e[1]).join('');

(async () => {
  { // every row; the rest finish out of order (e, c, d, b) and are reported in table order
    const io = recorder({ delays: { b: 40, c: 10, d: 25, e: 1 } });
    const code = await runGates(TABLE, ctx(), io);
    t.check(code === 0 && kinds(io, 'alone') === 'a' && kinds(io, 'start') === 'bcde', 'every row runs, the first alone, exit 0',
      `exit ${code}, alone ${kinds(io, 'alone')}, started ${kinds(io, 'start')}`);
    t.check(kinds(io, 'end') === 'ecdb', 'the rows after the first run side by side (they end out of table order)', kinds(io, 'end'));
    const want = [['out', 'B a\n'], ['out', 'OK a\n'], ['out', 'B b\n'], ['out', 'out b\n'], ['out', 'OK b\n'],
      ['out', 'B c\n'], ['out', 'out c\n'], ['out', 'B d\n'], ['out', 'out d\n'], ['out', 'OK d\n'],
      ['out', 'B e\n'], ['out', 'out e\n'], ['out', 'OK e\n']];
    t.check(JSON.stringify(printed(io)) === JSON.stringify(want),
      'reported in table order: banner, output, OK; a row with no OK prints none', JSON.stringify(printed(io)));
    const startD = io.log.find((e) => e[0] === 'start' && e[1] === 'd');
    t.check(startD && startD[2] === '--profile lean', 'a BUILD_ARGS row gets the build\'s arguments', JSON.stringify(startD));
    const firstStart = io.log.findIndex((e) => e[0] === 'start'), okA = io.log.findIndex((e) => e[0] === 'out' && e[1] === 'OK a\n');
    t.check(firstStart > okA && okA > io.log.findIndex((e) => e[0] === 'alone'), 'the first row runs alone: nothing starts before it has ended',
      JSON.stringify(io.log.slice(0, 5)));
  }
  { // the pool: never more than its size at once, every row still run
    const io = recorder({ delays: { b: 5, c: 5, d: 5, e: 5 } });
    const code = await runGates(TABLE, ctx(), io, 2);
    t.check(code === 0 && io.most() === 2 && kinds(io, 'start') === 'bcde', 'a pool of 2: two rows at once at most, all four run',
      `exit ${code}, most ${io.most()}, started ${kinds(io, 'start')}`);
  }
  { // WHEN: the tests not shipped drops b; --noSyntaxCheck drops everything
    const io2 = recorder(); await runGates(TABLE, ctx({ shipsTests: false }), io2);
    t.check(kinds(io2, 'alone') + kinds(io2, 'start') === 'acde', 'tests not shipped: the testsShipped row is passed over, every checked row runs',
      kinds(io2, 'alone') + kinds(io2, 'start'));
    const io3 = recorder(); const code3 = await runGates(TABLE, ctx({ noSyntaxCheck: true }), io3);
    t.check(code3 === 0 && io3.log.length === 0, '--noSyntaxCheck: nothing runs, nothing is printed, exit 0', JSON.stringify(io3.log));
  }
  { // a failing row (c) while e has ended and d still runs: c's banner and output, bell, its line on stderr, exit 1;
    // d is stopped and nothing after c is printed
    const io = recorder({ failing: new Set(['c']), delays: { b: 1, c: 10, d: 500, e: 1 } });
    const code = await runGates(TABLE, ctx(), io);
    t.check(code === 1, 'a failing row ends the run with exit 1', `exit ${code}`);
    const tail = printed(io).slice(-4);
    t.check(JSON.stringify(tail) === JSON.stringify([['out', 'B c\n'], ['out', 'out c\n'], ['bell'], ['err', 'F c\n']]),
      'the failing row prints its banner and output, then rings the bell, then prints its failure line on stderr',
      JSON.stringify(tail));
    t.check(kinds(io, 'stopped') === 'd' && !printed(io).some((e) => /[de]\n$/.test(e[1] || '')),
      'the row still running is stopped, and nothing after the failing row is printed', JSON.stringify(io.log));
  }
  { // no row starts once any row has failed: a pool of 2, b failing at once while c still runs, d and e never start
    const io = recorder({ failing: new Set(['b']), delays: { b: 1, c: 50, d: 1, e: 1 } });
    const code = await runGates(TABLE, ctx(), io, 2);
    t.check(code === 1 && kinds(io, 'start') === 'bc' && kinds(io, 'stopped') === 'c',
      'no row starts once a row has failed, and the one still running is stopped', `exit ${code}, ${JSON.stringify(io.log)}`);
  }
  { // the runner itself failing (its stdout gone, as at EPIPE) while rows run: every started row is stopped, then it rejects
    const io = recorder({ delays: { b: 1, c: 1, d: 500, e: 500 }, outThrowsOn: 'B d\n' });
    let threw;
    try { await runGates(TABLE, ctx(), io); } catch (e) { threw = e.message; }
    t.check(threw === 'EPIPE (planted)' && kinds(io, 'stopped') === 'de',
      'the runner failing mid-report stops every row still running before it rejects', `${threw} / ${JSON.stringify(io.log)}`);
  }
  { // a row that cannot even be started fails as a row, with what went wrong as its output
    const io = recorder({ unstartable: new Set(['e']) });
    const code = await runGates(TABLE, ctx(), io);
    const tail = printed(io).slice(-4);
    t.check(code === 1 && tail[0][1] === 'B e\n' && /^run-gates: could not start e: EMFILE \(planted\)\n$/.test(tail[1][1]) && tail[3][1] === 'F e\n',
      'a row that cannot be started is reported failing, its reason as its output, exit 1', `exit ${code}, ${JSON.stringify(tail)}`);
  }
  { // the first row failing: bell, its line, exit 1, and no other row starts
    const io = recorder({ failing: new Set(['a']) });
    const code = await runGates(TABLE, ctx(), io);
    t.check(code === 1 && kinds(io, 'start') === '' && JSON.stringify(printed(io)) === JSON.stringify([['out', 'B a\n'], ['bell'], ['err', 'F a\n']]),
      'the first row failing stops the run before any other row starts, exit 1', `exit ${code}, ${JSON.stringify(io.log)}`);
  }
  { // an unknown WHEN is a table error, never a silent skip: nothing runs, whatever the flags
    const BAD = [...TABLE, row('z', 'sometimes', 'OK z')];
    for (const [over, what] of [[{}, 'a checked build'], [{ noSyntaxCheck: true }, '--noSyntaxCheck']]) {
      const io = recorder();
      let threw;
      try { await runGates(BAD, ctx(over), io); } catch (e) { threw = e.message; }
      t.check(threw !== undefined && /z names an unknown when 'sometimes'/.test(threw) && io.log.length === 0,
        `a later row naming an unknown WHEN stops the run before any row runs (${what})`, `${threw} / ${JSON.stringify(io.log)}`);
    }
    t.check(tableErrorOf(TABLE) === undefined, 'a well-formed table has no table error');
  }
  { // the real table
    t.check(GATES.length > 0 && tableErrorOf(GATES) === undefined, 'gates.js has rows, each naming a known WHEN', tableErrorOf(GATES));
    // TESTS_REPO is where the build names the tests repo everywhere else (`../Fizzygum-tests` beside Fizzygum/, which
    // build_it_please.sh requires before anything runs): the tests repo's rows name their scripts under it
    t.check(TESTS_REPO === path.resolve(__dirname, '..', '..', 'Fizzygum-tests'),
      'gates.js TESTS_REPO is the Fizzygum-tests directory beside this repo', String(TESTS_REPO));
    const missing = GATES.filter((r) => !fs.existsSync(r.script));
    t.check(missing.length === 0, 'every gates.js row names a script that exists', missing.map((r) => r.script).join(', '));
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
    // a planted copy of the real runner beside a table of its own, its rows small node scripts
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'run-gates-selftest-'));
    try {
      // the runner verbatim but for its one library, which it loads from where it really is (gate-rules.js reaches the
      // pinned acorn by a path relative to itself, so a copy of the library beside the copy could not load)
      const runner = fs.readFileSync(path.join(__dirname, 'run-gates.js'), 'utf8');
      const LIB = "require('./lib/gate-rules')";
      t.check(runner.split(LIB).length === 2, 'the runner loads its one library as the planted copy expects', LIB);
      fs.writeFileSync(path.join(dir, 'run-gates.js'), runner.replace(LIB, `require(${JSON.stringify(path.join(__dirname, 'lib', 'gate-rules'))})`));
      const script = (name, body) => { fs.writeFileSync(path.join(dir, name), body); return name; };
      const gate = (name, when, ok) => `{ script: ${JSON.stringify(path.join(dir, name))}, args: [], when: '${when}', banner: 'B ${name}', `
        + `failure: 'F ${name}'${ok ? `, ok: 'OK ${name}'` : ''} }`;
      const table = (rows) => fs.writeFileSync(path.join(dir, 'gates.js'), `module.exports = { WHEN: ${JSON.stringify(WHEN)}, BUILD_ARGS: 'BUILD_ARGS',\n`
        + `  GATES: [${rows.join(', ')}] };\n`);
      // its own TMPDIR, so the temp dir of its captured output can be seen gone once it exits
      const tmp = path.join(dir, 'tmp');
      fs.mkdirSync(tmp);
      const run = (nsc = 'false') => spawnSync(process.execPath, [path.join(dir, 'run-gates.js'), `--noSyntaxCheck=${nsc}`, '--shipsTests=true', '--'],
        { encoding: 'utf8', cwd: dir, env: { ...process.env, TMPDIR: tmp } });
      // a malformed table: its second row names an unknown WHEN
      script('a.js', '');
      table([gate('a.js', 'checked'), gate('a.js', 'often')]);
      for (const nsc of ['false', 'true']) {
        const r = run(nsc);
        t.check(r.status === 2 && r.stdout === '' && /a\.js names an unknown when 'often'/.test(r.stderr),
          `a malformed table is refused with exit 2 before any row runs (--noSyntaxCheck=${nsc})`,
          `exit ${r.status}, out ${JSON.stringify(r.stdout)}, err ${JSON.stringify(r.stderr)}`);
      }
      // real rows: the second slow, writing to both of its streams; the third quick. Reported in order, exit 0
      const sleep = (ms) => `const until = Date.now() + ${ms}; while (Date.now() < until) {}\n`;
      script('one.js', "process.stdout.write('one\\n');\n");
      script('two.js', sleep(400) + "process.stderr.write('two to stderr\\n'); process.stdout.write('two to stdout\\n');\n");
      script('three.js', "process.stdout.write('three\\n');\n");
      table([gate('one.js', 'checked', true), gate('two.js', 'checked', true), gate('three.js', 'checked', true)]);
      const green = run();
      t.check(green.status === 0 && green.stderr === '' && green.stdout ===
        'B one.js\none\nOK one.js\nB two.js\ntwo to stderr\ntwo to stdout\nOK two.js\nB three.js\nthree\nOK three.js\n',
        'real rows finishing out of order are reported in table order, each row\'s stdout and stderr as ONE stream (stderr first, as written), exit 0',
        `exit ${green.status}, out ${JSON.stringify(green.stdout)}, err ${JSON.stringify(green.stderr)}`);
      t.check(fs.readdirSync(tmp).length === 0, 'the runner removes its temp dir when it exits', fs.readdirSync(tmp).join(', '));
      // the second row failing while the third (slow) still runs: its output, its failure on stderr, exit 1, no more
      script('two.js', "process.stdout.write('two failing\\n'); process.exit(3);\n");
      const marker = path.join(dir, 'three-finished');
      script('three.js', sleep(1500) + `require('fs').writeFileSync(${JSON.stringify(marker)}, 'x'); process.stdout.write('three\\n');\n`);
      const red = run();
      // (the bell is `tput bel`: a BEL on stdout, and with no terminal it may complain on stderr, before the failure line)
      t.check(red.status === 1 && red.stdout.replace(/\x07/g, '') === 'B one.js\none\nOK one.js\nB two.js\ntwo failing\n'
        && /(^|\n)F two\.js\n$/.test(red.stderr),
        'a real failing row ends the report: its output, its failure line on stderr, exit 1, nothing after it',
        `exit ${red.status}, out ${JSON.stringify(red.stdout)}, err ${JSON.stringify(red.stderr)}`);
      t.check(!fs.existsSync(marker) && fs.readdirSync(tmp).length === 0, 'the row still running when one failed is STOPPED (it never finished), and the temp dir is removed',
        `marker ${fs.existsSync(marker)}, tmp ${fs.readdirSync(tmp).join(', ')}`);
    } finally {
      fs.rmSync(dir, { recursive: true, force: true });
    }
  }
  t.done();
})();

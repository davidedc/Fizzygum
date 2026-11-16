#!/usr/bin/env node
'use strict';
// not-a-gate: the runner of the build's gates (gates.js); each row it launches is a gate with its own rules and proof
//
// run-gates.js — runs the build's static gates: the rows of buildSystem/gates.js, side by side, REPORTED in table order.
// The first row whose WHEN holds (the self-tests row) runs FIRST and ALONE, its output going out as it is written: a
// broken proof stops the build before any gate's verdict is read. Every other row whose WHEN holds then runs through a
// pool of POOL at a time, each with its stdout and stderr captured as ONE stream (a file in a temp dir), so a row's
// stderr text reaches the runner's stdout in its place in the row's output. The rows are reported in table order: a
// row's banner as soon as every row before it has been reported, then — once it has finished — its captured output and
// its OK line (so a row that hangs is the last banner printed). At the first failing row (in table order) the runner
// prints that row's output, rings the terminal bell (`tput bel`), prints the row's failure line on stderr, stops the
// rows still running, waits for them and exits 1: nothing after that row is printed, and no row starts once any row has
// failed. The temp dir is removed when the runner exits, and when SIGINT or SIGTERM stops it (the rows are stopped
// too). No row writes a file another row reads (a row writes only under a flag its row never passes, or a self-test's
// own temp files, and the self-tests row runs alone), so their order of running is free; only their report is ordered.
//
//   node ./buildSystem/run-gates.js --noSyntaxCheck=<true|false> --shipsTests=<true|false> -- <the build's arguments>
//
// The build (buildSystem/run-build.js, which build_it_please.sh launches) runs it from Fizzygum/ (once, after build.js
// has written the tree), passing its --noSyntaxCheck switch and the profile's shipsTests. The sibling tests repo, whose scripts some rows run, is never asked
// about here: the build requires it, and checks for it before anything else. Exit 0 when every row that ran passed, 1
// at the first that failed, 2 on a malformed command line or a malformed table — a row naming a WHEN the runner does
// not know: never a silent skip, it stops the run before ANY row runs, whatever the build's flags, --noSyntaxCheck
// included — and 2 when the runner itself fails (its stack printed, every started row stopped first). That the report
// order, the first row alone, the conditions, the stop and the exit codes hold is proven by run-gates-selftest.js.
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn, spawnSync } = require('child_process');
const { GATES, WHEN, BUILD_ARGS } = require('./gates');
// a whole buffer to a descriptor, waiting out a full non-blocking pipe (the gates' own exit lines go through it too)
const { writeAll } = require('./lib/gate-rules');

// rows at once after the first: run-selftests.js's NODE_POOL, the self-test runner's precedent for CPU-bound node work
const POOL = 8;

// What is wrong with a table, as one line — or undefined when every row names a WHEN the runner knows.
function tableErrorOf(rows) {
  const bad = rows.filter((row) => !WHEN.includes(row.when));
  if (bad.length === 0) return undefined;
  return `run-gates: ${bad.map((row) => `${path.basename(row.script)} names an unknown when '${row.when}'`).join('; ')}`
    + ` (known: ${WHEN.join(', ')})`;
}

// Does a (known) WHEN hold for this build?
function holds(when, { noSyntaxCheck, shipsTests }) {
  if (noSyntaxCheck) return false;
  if (when === 'testsShipped') return shipsTests;
  return true;
}

// Run `rows` for a build described by `ctx`, through `io`, with at most `pool` rows at once after the first → a promise
// of the exit code. `io` is { out(text), err(text), bell(), runAlone(script, args) → exit status (its output straight
// out), start(script, args) → { finished: promise of { status, output }, stop() } (its stdout and stderr captured as
// one) }. Pure but for io, so the self-test drives it on a table of its own. A malformed table rejects before any row
// runs; whatever else rejects, every row started is stopped and waited for first.
async function runGates(rows, ctx, io, pool = POOL) {
  const tableError = tableErrorOf(rows);
  if (tableError !== undefined) throw new Error(tableError);
  const argsOf = (row) => (row.args === BUILD_ARGS ? ctx.buildArgs : row.args);
  const [first, ...rest] = rows.filter((row) => holds(row.when, ctx));
  if (first === undefined) return 0;
  io.out(first.banner + '\n');
  if (io.runAlone(first.script, argsOf(first)) !== 0) {
    io.bell();
    io.err(first.failure + '\n');
    return 1;
  }
  if (first.ok !== undefined) io.out(first.ok + '\n');
  // the rest: started in table order, at most `pool` at once, each starting as another finishes, none once any row has
  // failed (every row before a failed one has started already: they start in table order)
  const runs = [];
  let running = 0, stopped = false;
  const startOne = (row) => {
    try { return io.start(row.script, argsOf(row)); } catch (e) {
      return { finished: Promise.resolve({ status: 1, output: `run-gates: could not start ${row.script}: ${e.message}\n` }), stop() {} };
    }
  };
  const startNext = () => {
    while (!stopped && running < pool && runs.length < rest.length) {
      const run = startOne(rest[runs.length]);
      runs.push(run);
      running++;
      run.finished.then(({ status }) => { running--; if (status !== 0) stopped = true; startNext(); });
    }
  };
  try {
    startNext();
    // reported in table order: a row's banner once every row before it is reported, its output once it has finished
    for (let i = 0; i < rest.length; i++) {
      const row = rest[i];
      io.out(row.banner + '\n');
      const { status, output } = await runs[i].finished;
      if (output && output.length) io.out(output);
      if (status !== 0) {
        io.bell();
        io.err(row.failure + '\n');
        return 1;
      }
      if (row.ok !== undefined) io.out(row.ok + '\n');
    }
    return 0;
  } finally {
    // whatever ended the report — a failing row, or the runner failing — no started row outlives it
    stopped = true;
    for (const run of runs) run.stop();
    await Promise.all(runs.map((run) => run.finished));
  }
}

module.exports = { runGates, tableErrorOf, POOL };

if (require.main === module) {
  const argv = process.argv.slice(2);
  const usage = 'usage: node ./buildSystem/run-gates.js --noSyntaxCheck=<true|false> --shipsTests=<true|false> -- <the build\'s arguments>';
  const sep = argv.indexOf('--');
  const own = sep < 0 ? argv : argv.slice(0, sep);
  const flag = (name) => {
    const given = own.filter((a) => a.startsWith(`--${name}=`));
    if (given.length !== 1) return undefined;
    const value = given[0].slice(name.length + 3);
    return value === 'true' ? true : value === 'false' ? false : undefined;
  };
  const noSyntaxCheck = flag('noSyntaxCheck');
  const shipsTests = flag('shipsTests');
  if (sep < 0 || own.length !== 2 || noSyntaxCheck === undefined || shipsTests === undefined) {
    console.error(usage);
    process.exit(2);
  }
  const tableError = tableErrorOf(GATES);
  if (tableError !== undefined) {
    console.error(tableError);
    process.exit(2);
  }
  // each pooled row's stdout and stderr go to ONE file of this dir (one descriptor for both, so they keep the order
  // the row wrote them in); the dir goes when the runner exits, and when a signal stops it, the live rows with it
  let dir;
  const files = () => dir || (dir = fs.mkdtempSync(path.join(os.tmpdir(), 'run-gates-')));
  const removeDir = () => { if (dir) fs.rmSync(dir, { recursive: true, force: true }); };
  process.on('exit', removeDir);
  const live = new Set();
  for (const [signal, number] of [['SIGINT', 2], ['SIGTERM', 15]]) {
    process.on(signal, () => {
      for (const child of live) child.kill(signal);
      removeDir();
      process.exit(128 + number);
    });
  }
  let made = 0;
  const io = {
    // every line written straight to its descriptor, so it lands in order with what the first row writes to its own
    out: (text) => writeAll(1, text),
    err: (text) => writeAll(2, text),
    bell: () => { spawnSync('tput', ['bel'], { stdio: 'inherit' }); },
    runAlone: (script, args) => spawnSync(process.execPath, [script, ...args], { stdio: 'inherit' }).status,
    start: (script, args) => {
      const file = path.join(files(), `${made++}-${path.basename(script)}.out`);
      const fd = fs.openSync(file, 'w');
      let child;
      try { child = spawn(process.execPath, [script, ...args], { stdio: ['ignore', fd, fd] }); } finally { fs.closeSync(fd); }
      live.add(child);
      // the output as BYTES, printed as the row wrote them
      const finished = new Promise((resolve) => {
        const done = (status) => { live.delete(child); resolve({ status, output: fs.readFileSync(file) }); };
        child.on('error', (e) => { fs.appendFileSync(file, `run-gates: could not run ${script}: ${e.message}\n`); done(1); });
        child.on('close', (code) => done(code === null ? 1 : code));
      });
      return { finished, stop: () => { if (live.has(child)) child.kill('SIGTERM'); } };
    },
  };
  runGates(GATES, { noSyntaxCheck, shipsTests, buildArgs: argv.slice(sep + 1) }, io)
    .then((code) => { process.exitCode = code; })
    .catch((e) => { writeAll(2, `run-gates: ${(e && e.stack) || e}\n`); process.exitCode = 2; });
}

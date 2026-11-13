#!/usr/bin/env node
'use strict';
// not-a-gate: the runner of the build's gates (gates.js); each row it launches is a gate with its own rules and proof
//
// run-gates.js — runs the build's static gates: the rows of buildSystem/gates.js, in order. For each row whose WHEN
// holds it prints the row's banner, runs its script with node (the build's own arguments where the row asks for them),
// and then either prints the row's OK line or — the script having exited non-zero — rings the terminal bell
// (`tput bel`), prints the row's failure line on stderr and stops with exit 1: no later row runs. Every line goes out
// as soon as it is written, in order with what the gates themselves print, so the build's transcript reads as one
// sequence.
//
//   node ./buildSystem/run-gates.js --noSyntaxCheck=<true|false> --shipsTests=<true|false> -- <the build's arguments>
//
// build_it_please.sh runs it from Fizzygum/ (once, after build.js has written the tree), passing its --noSyntaxCheck
// switch and the profile's PROFILE_SHIPS_TESTS. The sibling tests repo, whose scripts some rows run, is never asked
// about here: the build requires it, and checks for it before anything else. Exit 0 when every row that ran passed, 1
// at the first that failed, 2 on a malformed command line or a malformed table — a row naming a WHEN the runner does
// not know: never a silent skip, it stops the run before ANY row runs, whatever the build's flags, --noSyntaxCheck
// included. That the order, the conditions, the stop and the exit codes hold is proven by run-gates-selftest.js.
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const { GATES, WHEN, BUILD_ARGS } = require('./gates');

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

// Run `rows` for a build described by `ctx`, through `io` ({ out(text), err(text), run(script, args) → exit status,
// bell() }) → the exit code. Pure but for io, so the self-test drives it on a table of its own. A malformed table
// throws before any row runs.
function runGates(rows, ctx, io) {
  const tableError = tableErrorOf(rows);
  if (tableError !== undefined) throw new Error(tableError);
  for (const row of rows) {
    if (!holds(row.when, ctx)) continue;
    io.out(row.banner + '\n');
    const args = row.args === BUILD_ARGS ? ctx.buildArgs : row.args;
    const status = io.run(row.script, args);
    if (status !== 0) {
      io.bell();
      io.err(row.failure + '\n');
      return 1;
    }
    if (row.ok !== undefined) io.out(row.ok + '\n');
  }
  return 0;
}

module.exports = { runGates, tableErrorOf };

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
  // every line written straight to its descriptor, so it lands in order with what the gates write to theirs
  const io = {
    out: (text) => fs.writeSync(1, text),
    err: (text) => fs.writeSync(2, text),
    run: (script, args) => spawnSync(process.execPath, [script, ...args], { stdio: 'inherit' }).status,
    bell: () => { spawnSync('tput', ['bel'], { stdio: 'inherit' }); },
  };
  process.exitCode = runGates(GATES, { noSyntaxCheck, shipsTests, buildArgs: argv.slice(sep + 1) }, io);
}

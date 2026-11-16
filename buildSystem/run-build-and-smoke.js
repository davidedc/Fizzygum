#!/usr/bin/env node
'use strict';
// not-a-gate: the build-and-smoke check's sequencing — it launches the build and the boot smoke, which judge; it judges nothing itself
//
// run-build-and-smoke.js — `./build_and_smoke.sh [the build's arguments]` (a launcher: it cds to Fizzygum/, checks for
// node and runs this): the FULL build, then, if it succeeded, the headless boot smoke of every entry page the profile
// ships (../Fizzygum-tests/scripts/smoke-boot-headless.js). Exit 0 when both pass, 1 when the profile cannot be read,
// the build fails or the smoke fails, each said in its own line on stderr.
//
// WHICH SMOKE THIS TREE GETS is derived from the profile being built, by the same reader the build uses
// (lib/profile.js profileForBuild) — so this check cannot disagree with the build about what is in the tree it is
// about to boot. It used to pattern-match --homepage / --notests out of its arguments, which meant a third place that
// had to know what a flavour contains. The smoke's own four flags stay (its bite proof reads one dev tree as each
// other kind of tree through them); only the choice among them is made here:
//   form precompiled, sources none -> --lean: the production assertions + no source text.
//   form precompiled  -> --production: booted from the pre-compiled image, and no SWCanvas-only payload left in the
//                        tree. Implies the native leg only.
//   no SWCanvas entry -> --native-only: there is no index-sw.html to boot.
//   no harness entry  -> --no-harness-page: the profile ships SWCanvas pages without the test harness (dev-notests),
//                        so there is no worldWithSystemTestHarness.html.
// A launch is spelled `path.join(...)`, the one JavaScript launch lib/what-runs.js reads.

const path = require('path');
const { spawnSync } = require('child_process');
const { writeAll } = require('./lib/write-all');
const { profileForBuild, finishCommandLine } = require('./lib/profile');

const FIZZYGUM = path.resolve(__dirname, '..');
const out = (text) => writeAll(1, text);
const err = (text) => writeAll(2, text);

// one program, its output this check's own → its exit status (a signal or a launch that failed is a failure). Ctrl-C
// is the program's to answer, as run-build.js's run() says: one that dies of it ends this check by the same signal.
function run(program, args) {
  const r = spawnSync(program, args, { stdio: 'inherit' });
  if (r.error) { err(`build_and_smoke: ${program}: ${r.error.message}\n`); return 1; }
  if (r.signal === 'SIGINT') { process.removeAllListeners('SIGINT'); process.kill(process.pid, 'SIGINT'); }
  return r.status === null ? 1 : r.status;
}

// The smoke's flag for a profile, with the line that says why → { flag, line } (none for a profile that ships every
// entry page)
function smokeFor(p) {
  if (p.form === 'precompiled' && p.sources === 'none') {
    return { flag: '--lean', line: `(profile ${p.name} is an appliance build -> boot smoke runs the production assertions + no-source-text)` };
  }
  if (p.form === 'precompiled') return { flag: '--production', line: `(profile ${p.name} is precompiled -> boot smoke runs native-only + production-tree assertions)` };
  if (!p.shipsSWCanvasEntry) return { flag: '--native-only', line: `(profile ${p.name} ships no SWCanvas entry page -> boot smoke runs native-only)` };
  if (!p.shipsHarnessEntry) return { flag: '--no-harness-page', line: `(profile ${p.name} ships no test-harness page -> boot smoke skips the harness-page leg)` };
  return {};
}

function main(argv) {
  process.chdir(FIZZYGUM);
  process.on('SIGINT', () => {});
  let profile;
  try { profile = profileForBuild(argv).profile; } catch (e) {
    finishCommandLine(e, 'profile.js');
    err('build_and_smoke: could not read the build profile -- aborting.\n');
    return 1;
  }
  const { flag, line } = smokeFor(profile);
  if (line) out(line + '\n');
  out('==> building (with CoffeeScript syntax gate) ...\n');
  if (run('./' + path.join('build_it_please.sh'), argv)) {
    err('build_and_smoke: BUILD stage failed -- aborting (boot smoke not run).\n');
    return 1;
  }
  out('\n');
  out('==> boot smoke test ...\n');
  if (run('node', [path.join('..', 'Fizzygum-tests', 'scripts', 'smoke-boot-headless.js'), ...(flag ? [flag] : [])])) {
    err('build_and_smoke: SMOKE stage failed.\n');
    return 1;
  }
  out('\n');
  out('build_and_smoke: OK (build + boot smoke passed).\n');
  return 0;
}

module.exports = { smokeFor };

if (require.main === module) process.exitCode = main(process.argv.slice(2));

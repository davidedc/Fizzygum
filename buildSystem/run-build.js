#!/usr/bin/env node
'use strict';
// not-a-gate: the build's sequencing — it launches the build's tools and its gate runner (run-gates.js, whose rows are the gates); it judges nothing itself
//
// run-build.js — THE BUILD: `./build_it_please.sh [--profile <name>] [--noSyntaxCheck]` (a launcher of a few lines: it
// cds to Fizzygum/, checks for node and runs this) writes ../Fizzygum-builds/latest. In order: the arguments, the
// layout, the vendored engine, the start marker and the record of the inputs, the toolchain, the profile, the clean,
// the tests link, the assembly (build.js), the gates (run-gates.js), the boot bundle (compiled, minified, stamped,
// fronted by its engine), the fonts, the boot scripts, the pre-compiled image for a profile that ships one, and the
// stamp. Each step's comment says why it is the way it is.
//
// A BUILD FLAVOUR IS A PROFILE, NOT A FLAG (arc 5). buildSystem/profiles/<name>.json declares three facts -- which
// parts ship, which code form, which entry pages -- and buildSystem/lib/profile.js DERIVES from them everything this
// build used to decide by asking "is this the homepage?": the tests link, BUILDFLAG_LOAD_TESTS, which build gates run,
// the boot-bundle prelude, whether the SWCanvas bundle and its ~90 MB of font assets are built, and whether the
// pre-compile driver runs. The --homepage and --notests flags are GONE; so is the per-flavour list of files to delete
// again at the end of a build. `--profile homepage` and `--profile dev-notests` replace them.
//
// Examples:
//   ./build_it_please.sh
//     the dev profile (the default): every part, compiled in the browser, all three entry pages
//   ./build_it_please.sh --profile homepage
//     the production artifact: pre-compiled, native-only, no test machinery
//   ./build_it_please.sh --profile dev-notests
//     the dev world with the test machinery left out
//
// THE PORT FROM BASH (docs/archive/build-node-port-plan.md). The trees it writes, the lines it prints and the ways it
// fails are the bash script's: the same programs launched with the same arguments (the compiler, the minifier, node,
// git, and the file utilities rm, mkdir, cp, ln, mv, touch and cat, so a failing one says what it said there, and
// `tput bel` for the bell), every line of its own written straight to its descriptor so it lands in order with what
// the programs write, and every exit 1. What is not the bash script's, each a ruling of the plan's §3: the profile is
// asked in this process (lib/profile.js profileForBuild, where bash eval'd its `--shell` output); the files it reads
// by name are named once, here (READS_BY_NAME, which lib/build-inputs.js requires); the `node` check is the
// launcher's; and the cleaner refuses a tree that is not ../Fizzygum-builds/latest and a recursive removal of a path
// spelled with a trailing slash. A launch is spelled `path.join(...)`, the one JavaScript launch lib/what-runs.js reads.
//
// Exit 0 when the tree is built and stamped; 1 at the first step that fails, before the tree is stamped.

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
// NOT lib/gate-rules.js: that loads acorn, which the toolchain check below must be able to report missing
const { writeAll } = require('./lib/write-all');
const { profileForBuild, finishCommandLine } = require('./lib/profile');

// THE LAYOUT, relative to Fizzygum/ (the working directory: the launcher cds there, and so does main())
const BUILD_PATH = '../Fizzygum-builds/latest';
const SCRATCH_PATH = BUILD_PATH + '/delete_me';
const JSSRC_SCRATCH = SCRATCH_PATH + '/js-src';
const BOOT_MIN = BUILD_PATH + '/js/fizzygum-boot-min.js';
const TESTS_LINK = BUILD_PATH + '/js/tests';
const START = BUILD_PATH + '/.build-start';
const STAMP = BUILD_PATH + '/.build-stamp';
const RECORD = '.latest-build-inputs';

// Mirrors SWCanvas's own BitmapText auto-fetch gate. The bulk SWCanvas bytes are gitignored; on a fresh clone we fetch
// them from the committed pin so that "git clone && build" Just Works (needs GitHub access on the first build only).
const SWCANVAS_VENDOR = 'vendor/swcanvas';
const SWCANVAS_PIN = 'vendor/swcanvas.pin';

// THE FILES THE BUILD READS BY NAME, outside the partition (the parts' sources, assets and vendor pieces are
// parts.json's): named here and nowhere else — lib/build-inputs.js records each as an input of every build, so a
// rename here is a rename there.
const READS_BY_NAME = {
  detTrig: 'runtime-prelude/deterministic-trig.js',
  swcanvas: SWCANVAS_VENDOR + '/swcanvas.min.js',
  sw3d: SWCANVAS_VENDOR + '/sw3d.js',
  preCompiledStub: 'assets/pre-compiled.js',
};

// ---- writing, launching, stopping ---------------------------------------------------------------------------------

const out = (text) => writeAll(1, text);
const err = (text) => writeAll(2, text);

// A step that ends the build: its exit code, carried to main()
class Stop { constructor(code) { this.code = code; } }

// What the shell said of a file it could not open for a redirection (`build_it_please.sh: <file>: <reason>`), less the
// line number only the shell knows
const REASONS = { EACCES: 'Permission denied', ENOENT: 'No such file or directory', EISDIR: 'Is a directory',
  ENOTDIR: 'Not a directory', ENOSPC: 'No space left on device', EROFS: 'Read-only file system', EPERM: 'Operation not permitted' };
const reason = (e) => REASONS[e.code] || e.message;

// CTRL-C reaches the build and the program it is running alike (one process group). As the shell did, the build waits
// for that program, and the program decides: one that handles the signal and exits (run-gates.js stops its rows, the
// pre-compile driver closes its browser) is a step that failed, said as any failure is; one that DIES of it ends the
// build by the same signal, as the shell then ended itself. So the signal does not kill the build itself (main()
// installs a handler that does nothing: every step is synchronous, so it could only run once the build has ended),
// and run() re-raises it when the program died of it. (A Ctrl-C in the moments between two programs, which the shell
// would have died of, reaches no program, and the build goes on.)
function reRaiseInterrupt() {
  process.removeAllListeners('SIGINT');
  process.kill(process.pid, 'SIGINT');
}

// One program, its output the build's own; its exit status (a signal or a launch that failed is a failure, as the
// shell's `$?` made it). A program that cannot be started is said as the shell said it: a working directory that is not
// there as the `cd` before it said it, a name looked up on PATH as "command not found", a path tried as the system's
// reason.
function run(program, args, opts = {}) {
  if (opts.cwd !== undefined && !isDirectory(opts.cwd)) {
    err(`build_it_please.sh: cd: ${opts.cwd}: No such file or directory\n`);
    return 1;
  }
  const r = spawnSync(program, args, { stdio: opts.stdio || 'inherit', cwd: opts.cwd });
  if (r.error) {
    err(`build_it_please.sh: ${program}: ${r.error.code === 'ENOENT' && !program.includes('/') ? 'command not found' : reason(r.error)}\n`);
    return 127;
  }
  if (r.signal === 'SIGINT') reRaiseInterrupt();
  return r.status === null ? 1 : r.status;
}

// The bell (`tput bel`, launched as the shell launched it: what it writes, and whether, is the terminal's business)
function bell() { run('tput', ['bel']); }

// A STEP THAT FAILED stops the build here, before the tree is stamped (the stamp is the build's last act, so a tree
// missing a piece is never tested as complete): the build's own error idiom, for a step written
// `<step> || buildFailed('<what it was doing>')`. Every step that builds, copies, links or removes a piece of the tree
// checks its own exit, by hand where it has a remedy of its own to give, else through here; the unchecked ones are the
// appends of a generated line, the boot prelude's pieces (lib/profile.js has checked each exists) and the removals of
// intermediates.
function buildFailed(what) {
  bell();
  err(`!!!!!!!!!!! error: ${what} failed\n`);
  throw new Stop(1);
}

// `<program> <args> {>|>>} <file>`: the file opened (truncated or appended to) before the program runs, as the shell
// opens a redirection; a file that cannot be opened fails the command without running it
function runInto(file, flags, program, args) {
  let fd;
  try { fd = fs.openSync(file, flags); } catch (e) { err(`build_it_please.sh: ${file}: ${reason(e)}\n`); return 1; }
  try { return run(program, args, { stdio: ['ignore', fd, 'inherit'] }); } finally { fs.closeSync(fd); }
}
const catInto = (file, flags, source) => runInto(file, flags, 'cat', [source]);

// `printf … >> <file>`: 0, or 1 with the shell's words for a file it could not open
function append(file, text) {
  try { fs.appendFileSync(file, text); return 0; } catch (e) { err(`build_it_please.sh: ${file}: ${reason(e)}\n`); return 1; }
}

// `[ -d p ]`, `[ -f p ]`, `[ -L p ]`
const isDirectory = (p) => { try { return fs.statSync(p).isDirectory(); } catch (e) { return false; } };
const isFile = (p) => { try { return fs.statSync(p).isFile(); } catch (e) { return false; } };
const isLink = (p) => { try { return fs.lstatSync(p).isSymbolicLink(); } catch (e) { return false; } };

// `<dir>/*<suffix>` as the shell expands it: the entries not starting with a dot, sorted; the pattern itself when none
// matches (so the program reports the pattern, as it did)
function glob(dir, suffix) {
  let names = [];
  try { names = fs.readdirSync(dir).filter((n) => !n.startsWith('.') && n.endsWith(suffix)).sort(); } catch (e) { /* none */ }
  return names.length ? names.map((n) => dir + '/' + n) : [dir + '/*' + suffix];
}

// ---- the cleaner ---------------------------------------------------------------------------------------------------

// The tree this build may clean: ../Fizzygum-builds/latest and nothing else. A recursive removal anywhere else, or
// of a path spelled with a trailing slash (which makes `rm -rf` follow a symbolic link into its target), is refused
// before anything is removed.
function checkTree(tree) {
  if (!path.resolve(tree).endsWith(path.sep + path.join('Fizzygum-builds', 'latest'))) {
    err(`run-build: refusing to clean ${tree}: the build's tree is ../Fizzygum-builds/latest\n`);
    throw new Stop(1);
  }
}
function removeTree(p, what, tree = BUILD_PATH) {
  const inside = path.relative(path.resolve(tree), path.resolve(p));
  if (p.endsWith('/') || inside === '' || inside.startsWith('..') || path.isAbsolute(inside)) {
    err(`run-build: refusing to remove ${p}: not a path inside ${tree}, spelled without a trailing slash\n`);
    throw new Stop(1);
  }
  if (run('rm', ['-rf', p])) buildFailed(what);
}

// ---- the test-serving link: the ONLY two operations allowed on js/tests ----
//
// js/tests is a relative SYMLINK to the sibling tests repo's tests/ directory (made by linkTests), so the built world
// serves the tests where they actually live — no copy. That makes the path DANGEROUS to spell casually: a
// trailing-slash `rm -rf latest/js/tests/` or a `find -L` over the build tree DELETES THE REAL TESTS through the link
// (measured), while the slash-less form only removes the link. So this build contains exactly two operations on that
// path, and nothing else may touch it:
//   - removeTestsLink below;
//   - the single `ln -sfn` that creates it (-n so a re-run REPLACES the link instead of writing a stray link INSIDE
//     the target).
// Recursive operations on js/tests are banned in any spelling.
//
// The path only ever holds a SYMLINK (a tests-stripped build creates nothing there at all), so this is one `rm -f`
// after an lstat — which refuses a directory outright and cannot recurse. No spelling here, even a wrong one, can
// reach the real tests through the link.
function removeTestsLink(tree = BUILD_PATH) {
  const link = tree + '/js/tests';
  if (isLink(link) && run('rm', ['-f', link])) buildFailed('removing the previous tests link');
}

// ---- the steps -----------------------------------------------------------------------------------------------------

// The arguments are kept whole and passed on unchanged to build.js and run-gates.js (and read by lib/profile.js). NOTE
// what is NOT decided here: the build FLAVOUR. That is --profile, read by lib/profile.js, so that this build,
// build_and_smoke.sh and build.js cannot disagree about which profile is being built. --noSyntaxCheck skips every
// static gate, the CoffeeScript syntax gate among them (default: they run). → { noSyntaxCheck }
function readArguments(argv) {
  let noSyntaxCheck = false;
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--profile') {
      // The NAME is lib/profile.js's business (it reads the whole list); here only both tokens are stepped over so
      // the rest of the loop sees the next real flag.
      if (argv[i + 1] === undefined || argv[i + 1] === '') {
        err('build_it_please.sh: --profile needs a name, e.g. --profile homepage\n');
        throw new Stop(1);
      }
      i++;
    } else if (a.startsWith('--profile=')) {
      // (the name is lib/profile.js's)
    } else if (a === '--noSyntaxCheck') {
      // consumed here only; it is ALSO a no-op in build.js, so the forwarded list (which still contains it) does not
      // trip build.js's argument parsing
      noSyntaxCheck = true;
    } else {
      // An unknown argument used to be forwarded silently, so a typo (or the retired --homepage / --notests) reached
      // build.js's argument reader -- or nothing at all -- and the build made something other than what was asked
      // for. Say so instead. (The profiles are listed by their file names' order, `.json` and all, as `ls` sorted
      // them.)
      let names = [];
      try { names = fs.readdirSync('buildSystem/profiles').filter((n) => !n.startsWith('.') && n.endsWith('.json')).sort(); } catch (e) { /* none */ }
      err(`build_it_please.sh: unknown argument '${a}'.\n` +
        `  A build flavour is a PROFILE: --profile <name>, one of ${names.map((n) => n.replace(/\.json$/, '') + ' ').join('')}\n` +
        '  (--homepage and --notests were retired: use --profile homepage / --profile dev-notests.)\n' +
        '  Other options: --noSyntaxCheck\n');
      throw new Stop(1);
    }
  }
  return { noSyntaxCheck };
}

// The umbrella, and the sibling tests repo, which is a REQUIREMENT of every build, whatever the profile ships: checked
// here, up front, so nothing below needs a branch for its absence. A missing Fizzygum-builds is made.
function checkLayout() {
  if (!isDirectory('../../Fizzygum-all')) {
    // exit NON-ZERO: a bare `exit` here once returned the last echo's 0, so an aborted build read as SUCCESS — a
    // baseline clone under a mis-named umbrella "built" green while writing NOTHING and an A/B ran vacuously against
    // the wrong build (ordered-downwalk plan §11, 2026-07-16).
    out('\n----------- error -------------\nYou miss the overarching Fizzygum directory.\n' +
      '...the directory structure should be\nFizzygum-all\n- Fizzygum\n- Fizzygum-builds\n- Fizzygum-tests\n- Fizzygum-website\n\n');
    throw new Stop(1);
  }
  if (!isDirectory('../Fizzygum-tests')) {
    out('\n----------- error -------------\n' +
      'The sibling Fizzygum-tests repo is required, and there is none at ../Fizzygum-tests.\n' +
      'Every build needs it, whatever the profile ships:\n' +
      "  - the harness part's sources live there (Automator-and-test-harness-src/);\n" +
      "  - the precompiled profiles' image driver lives there (its scripts/);\n" +
      "  - the build's gates read it (the harness is compiled code like src/, and its scripts are gates).\n" +
      'Check it out beside this repo, inside Fizzygum-all.\n\n');
    throw new Stop(1);
  }
  if (!isDirectory('../Fizzygum-builds')) {
    out("\n----------- warning! -------------\nYou miss the destination Fizzygum-builds directory.\n" +
      "I'll create one for you, but ideally you should have\nchecked-out such directory from github\n\n");
    run('mkdir', ['../Fizzygum-builds']);
  }
}

// The vendored engine. The 3D-core artifacts are part of the presence check too: a vendor tree that predates that dist
// target would silently fail the native bundle's assembly, so it is treated as not-populated and re-fetched. A pin
// that differs from the vendored VERSION is only a warning (not auto-refreshing, to avoid a surprise long build).
function vendorEngine() {
  const pieces = ['swcanvas.min.js', 'sw3d.js', 'swcanvas-3d-core.min.js', 'sw3d.min.js', 'VERSION'];
  if (!pieces.every((p) => isFile(SWCANVAS_VENDOR + '/' + p))) {
    out(`SWCanvas bundle (incl. sw3d.js + the 3D-core target) missing — fetching from ${SWCANVAS_PIN} ...\n`);
    if (run('./' + path.join('scripts', 'vendor-swcanvas.sh'), [])) buildFailed('fetching the vendored SWCanvas (./scripts/vendor-swcanvas.sh)');
  } else if (isFile(SWCANVAS_PIN)) {
    const sha = (f) => {
      try { return fs.readFileSync(f, 'utf8').replace(/[ \t\n\v\f\r]/g, ''); } catch (e) { err(`build_it_please.sh: ${f}: ${reason(e)}\n`); return ''; }
    };
    const pinned = sha(SWCANVAS_PIN), vendored = sha(SWCANVAS_VENDOR + '/VERSION');
    if (pinned !== vendored) {
      out(`warning: vendor/swcanvas.pin (${pinned}) != vendored SWCanvas (${vendored}).\n` +
        '         Run ./scripts/vendor-swcanvas.sh to refresh (not auto-refreshing to avoid a surprise long build).\n');
    }
  }
}

// THE BUILD'S START, before it reads any input (lib/build-inputs.js says what those are) and after the vendored
// SWCanvas above is in place (a fresh clone fetches it: inputs this build only produced must not read newer than its
// stamp): a start marker is laid, whose mtime the stamp takes at the very end, so an input edited WHILE this build runs
// reads newer than its stamp. The previous stamp goes at the build's first write (the clean below). With the marker,
// WHAT the build is about to read, each input with its mtime and size (lib/build-inputs.js --record): a record promoted
// with the stamp, so an input deleted, renamed, added or put back with an older time since this build is seen too,
// which no comparison of times with the stamp shows. It is kept OUTSIDE the tree the build writes
// (Fizzygum/.latest-build-inputs, gitignored): a record of the developer's inputs is no part of an artifact, and
// anything derived from the inputs inside the tree would differ between any two builds `fg fingerprint` compares.
function startRecord() {
  run('mkdir', ['-p', BUILD_PATH]);
  run('touch', [START]);
  if (runInto(RECORD + '.reading', 'w', 'node', [path.join('buildSystem', 'lib', 'build-inputs.js'), '--record', START])) {
    buildFailed("recording the build's inputs (buildSystem/lib/build-inputs.js)");
  }
}

// THE TOOLCHAIN is the one package.json and its lockfile pin, installed by `npm ci` in Fizzygum/: the CoffeeScript that
// compiles the boot files and the terser that minifies them and the pre-compiled image, and the two libraries the
// static gates load: acorn (lib/js-mask.js, lib/call-sites.js) and the complexity analyzer (lib/cognitive-complexity.js).
// The artifact's bytes depend on the first two, and the gates' verdicts on the last two, so all four are chosen
// (package.json, exact versions), never whatever a machine has installed. Each runs from its OWN package --
// node_modules/.bin/coffee is a link two packages declare (coffeescript-v1 has a `coffee` too) -- and an install whose
// version is not the pinned one (an older `npm install`, a partial one) stops the build here. → { COFFEE, TERSER }
function checkToolchain() {
  const COFFEE = process.cwd() + '/node_modules/coffeescript/bin/coffee';
  const TERSER = process.cwd() + '/node_modules/terser/bin/terser';
  let pins;
  try { pins = JSON.parse(fs.readFileSync('package.json', 'utf8')).devDependencies; } catch (e) {
    err(String((e && e.stack) || e) + '\n');
    throw new Stop(1);
  }
  for (const name of ['coffeescript', 'terser', 'acorn', 'coffeescript-cognitive-complexity']) {
    let installed = 'not installed';
    try { installed = JSON.parse(fs.readFileSync('node_modules/' + name + '/package.json', 'utf8')).version; } catch (e) { /* not installed */ }
    if (installed !== pins[name]) {
      out(`${name} in Fizzygum/node_modules is ${installed}, not the ${pins[name]} package.json pins: run npm ci in Fizzygum/.\n`);
      throw new Stop(1);
    }
  }
  out('coffeescript version -------------\n');
  run(COFFEE, ['--version']);
  return { COFFEE, TERSER };
}

// ---- THE FLAVOUR: resolve the profile ----
// lib/profile.js loads buildSystem/profiles/<name>.json (default: dev) and hands back the derived facts this build
// needs (profileForBuild: the profile, and the boot pieces and scripts its parts ship, their declarations checked
// first). It gets the WHOLE arg list because it owns --profile parsing for every caller. A profile it refuses stops
// the build: a nameless flavour is never built. → { profile, prelude, scripts }
function readProfile(argv) {
  let facts;
  try { facts = profileForBuild(argv); } catch (e) {
    finishCommandLine(e, 'profile.js');
    bell();
    err('!!!!!!!!!!! error: could not read the build profile -- aborting build.\n');
    throw new Stop(1);
  }
  const p = facts.profile;
  out(`profile: ${p.name} — form ${p.form}, tests ${p.shipsTests}, SWCanvas entry ${p.shipsSWCanvasEntry}\n`);
  return facts;
}

// ---- cleanup ----
// The build's first write: the previous stamp goes with the tree it described, so a build that does not complete
// leaves NONE — never the last good build's, which would let a runner test whatever this one left half-written. (A
// build that stops before this point, on an unknown profile or a missing tool, leaves the previous tree and its
// stamp.) The tests link is dropped BEFORE js/ is wiped — `rm -rf` on a directory CONTAINING a symlink removes the
// link and never descends through it (verified), but removing it first means the recursive delete never meets a
// symlink at all. The scratch is this build's own: a build that stopped half-way left its intermediates, which the
// boot bundle's appends would otherwise build on.
function clean(tree = BUILD_PATH) {
  checkTree(tree);
  if (run('rm', ['-f', tree + '/.build-stamp', RECORD])) buildFailed("removing the previous build's stamp and record");
  if (run('rm', ['-rf', ...glob(tree, '.html')])) buildFailed('removing the previous entry pages');
  removeTree(tree + '/icons', 'removing the previous icons', tree);
  removeTestsLink(tree);
  removeTree(tree + '/js', 'removing the previous js tree', tree);
  for (const [dir, what] of [['/js', 'the js directory'], ['/icons', 'the icons directory'], ['/js/libs', 'the js/libs directory'],
    ['/js/coffeescript-sources', 'the class sources directory'], ['/js/src', 'the js/src directory']]) {
    if (!isDirectory(tree + dir) && run('mkdir', [tree + dir])) buildFailed('making ' + what);
  }
  removeTree(tree + '/delete_me', 'removing the previous scratch directory', tree);
  if (run('mkdir', [tree + '/delete_me'])) buildFailed('making the scratch directory');
}

// ---- serve the tests through a link instead of copying them in ----
// js/tests -> the sibling tests repo's tests/ directory. RELATIVE (so the whole umbrella can be moved/renamed), and
// from latest/js that is three levels up to Fizzygum-all/ then down into Fizzygum-tests/tests. Everything loads over
// file:// by <script> injection, which follows the link happily on both engines the suite drives.
// A build whose profile does not ship the harness part ships NO js/tests entry at all: a precompiled profile's
// pre-compile pass boots ?generatePreCompiled, and that boot loads no test machinery whatsoever (the load condition is
// plain BUILDFLAG_LOAD_TESTS — see globalFunctions.coffee), so it needs nothing here.
// The two manifests the booting world loads (js/tests/testsManifest.js + testsAssetsManifest.js) are DERIVED from the
// tests/ tree and gitignored, so they are generated here — that keeps "build, then open index.html in a browser"
// working with no extra step. Every headless runner and capture script ALSO regenerates them at startup, which is what
// makes a stale manifest impossible: a test added after this build is picked up with no rebuild. (This is deliberately
// NOT gated on --noSyntaxCheck; it is not a check.)
function linkTests(profile) {
  if (!profile.shipsTests) { removeTestsLink(); return; }
  if (run('ln', ['-sfn', '../../../Fizzygum-tests/tests', TESTS_LINK])) buildFailed('linking the tests (js/tests)');
  if (run('node', [path.join('..', 'Fizzygum-tests', 'scripts', 'generate-tests-manifests.js'), '--quiet'])) throw new Stop(1);
}

// ---- the assembly ----
// buildSystem/build.js wraps every class's source into the SourceVault batches, writes the parts manifest, generates
// the entry pages and copies each part's assets. The flavour reaches it as --profile <name> inside the arguments (it
// resolves the profile itself, through the same lib/profile.js), and that decides which parts' sources it wraps,
// which assets and vendor payloads it writes, and which entry pages it generates.
// ⚠ ITS EXIT IS CHECKED: for years this step had NO check at all, so the single most important step of the build
// could fail outright and the build still printed "done!!!" and exited 0. Found 2026-07-30 by planting a
// deliberately missing part asset: the build step correctly printed its ERROR and exited 1, and the build reported OK.
function assemble(argv) {
  if (run('node', ['./' + path.join('buildSystem', 'build.js'), ...argv])) {
    bell();
    err('!!!!!!!!!!! error: buildSystem/build.js failed -- aborting build.\n');
    throw new Stop(1);
  }
}

// --- THE GATES: buildSystem/gates.js, run by buildSystem/run-gates.js ---
// One row per static gate the build runs: its script, its arguments, when it runs and what it prints. The runner runs
// the rows side by side, reports them in table order and stops the build at the first gate that fails, ringing the
// bell with that gate's own failure line; every gate stands behind the --noSyntaxCheck escape hatch, and four of the
// tests repo's gates run only where the profile ships the tests (the table says which; the repo itself is always
// there, checked up front). A row naming a condition the runner does not know stops the build before any gate runs.
// Why each gate exists sits above its row in the table; what it checks and what it cannot see:
// docs/architecture/lint-and-static-checks.md. The self-tests run FIRST, as the first row, alone: a gate whose own
// proof fails gives verdicts not worth reading.
function runGates(argv, noSyntaxCheck, profile) {
  if (run('node', ['./' + path.join('buildSystem', 'run-gates.js'), `--noSyntaxCheck=${noSyntaxCheck}`, `--shipsTests=${profile.shipsTests}`, '--', ...argv])) {
    throw new Stop(1);
  }
}

// ---- the boot bundle's source, in the scratch dir ----
// The one runtime flag that says "this build has test machinery in it" -- which is precisely whether the harness part
// ships. It used to be its own pair of flavour flags, i.e. the same fact spelled twice, with nothing making the two
// agree. Then WHEN (or whether) the reflective layer loads -- the class source text plus the meta-system that parses
// it. globalFunctions reads this; lib/profile.js's SOURCES_POLICIES documents the values. "none" ships no source text
// at all, so the boot must not go looking for it.
// The parts manifest (window.FIZZYGUM_PARTS: per part, its batch files, eagerness and vendor payloads) goes IN the
// bundle rather than being fetched: the batch loader needs it immediately. build.js writes it from
// buildSystem/parts.json. It is data nothing reads until boot runs, so it sits with the build flags in the bundle's
// generated head.
// Then the boot itself: every shipping part's `bootPrelude` pieces (buildSystem/parts.json), in the partition's order
// -- core's own first (the SourceVault, which every sources_batch_*.js needs before it runs, then globalFunctions and
// the built-in prototype extensions), then e.g. fizzytiles' numbertimes.coffee. The order is data in parts.json,
// never a list in this build.
function bootSource(profile, prelude) {
  const boot = SCRATCH_PATH + '/fizzygum-boot.coffee';
  run('touch', [boot]);
  append(boot, `BUILDFLAG_LOAD_TESTS = ${profile.shipsTests}\n`);
  append(boot, `BUILDFLAG_SOURCES = '${profile.sources}'\n`);
  out('compiling boot file...\n');
  append(boot, '\n');
  if (catInto(boot, 'a', SCRATCH_PATH + '/partsManifest.coffee')) buildFailed('adding the parts manifest to the boot bundle');
  for (const piece of prelude) {
    append(boot, '\n');
    catInto(boot, 'a', piece);
  }
}

// Stamp the build with its SOURCE COMMIT, never the wall clock. `buildVersion` is a human affordance only — nothing
// reads it in code; you type it in the browser console to see which build you are looking at — but it ships in BOTH
// boot bundles, so whatever goes in here lands in their bytes. With the date in it, every build of identical sources
// produced a different bundle, which made a byte/hash comparison useless for the one question it should answer: "did
// this bundle actually change?". A commit id answers "which build is this?" at least as well AND is a pure function of
// the sources, so two builds of a clean tree at the same commit are byte-identical. All three git reads degrade to a
// harmless literal outside a git checkout (e.g. a source tarball), and a dirty tree cannot be named by a commit, so it
// says so rather than claim the commit's identity. It is APPENDED TO THE MINIFIED bundle (minifyBoot), never compiled
// into its source: terser's mangler picks local names by the character frequencies of the whole input, so a stamp
// inside it renamed locals whenever the stamp changed (a dirty tree's " +local-changes" alone did it) — the minified
// code would not be a function of the sources alone. → the line
function buildVersion() {
  // one git read's stdout, its stderr silenced; the fallback when git fails (as `$(git … 2>/dev/null || echo x)`)
  const git = (args, fallback) => {
    const r = spawnSync('git', args, { stdio: ['ignore', 'pipe', 'ignore'], encoding: 'utf8' });
    const text = r.stdout || '';
    return (r.status === 0 ? text : text + fallback + '\n').replace(/\n+$/, '');
  };
  const sha = git(['rev-parse', '--short', 'HEAD'], 'no-git');
  const when = git(['log', '-1', '--format=%cI'], 'unknown-date');
  const dirty = git(['status', '--porcelain'], '').length ? ' +local-changes' : '';
  return `\n;var buildVersion='Fizzygum ${sha} (${when})${dirty}';\n`;
}

// The boot source, compiled into the SCRATCH dir, not the build tree: no entry page ever loads the unminified boot JS,
// so it is an intermediate like the bare minified file (which the bundles below remove with the same reasoning).
// Keeping intermediates out of the tree is what makes "what a flavour ships" derivable instead of something a
// per-flavour prune list has to remember. Then minified, and stamped after the minifier, so the stamp cannot reach the
// mangled names.
function minifyBoot({ COFFEE, TERSER }, stamp) {
  if (run(COFFEE, ['-b', '-c', '-o', SCRATCH_PATH + '/', SCRATCH_PATH + '/fizzygum-boot.coffee'])) buildFailed("compiling the boot bundle's CoffeeScript");
  out('... done compiling boot file\n');
  out('minifying boot file...\n');
  if (run(TERSER, ['--compress', '--mangle', '--output', BOOT_MIN, '--', SCRATCH_PATH + '/fizzygum-boot.js'])) {
    bell();
    err('!!!!!!!!!!! error: minifying the boot file failed!\n');
    throw new Stop(1);
  }
  if (append(BOOT_MIN, stamp)) buildFailed('stamping the boot bundle');
  out('... done minifying boot file\n');
}

// ---- the two boot bundles ----
//
// The rendering backend is a BUILD-TIME property of the entry page, so the SAME minified boot JS is fronted by two
// different engine preludes and each page (lib/profile.js's ENTRY_PAGES) loads the one carrying the engine it can
// actually use. That way no artifact ships an engine it will never call, and there is no runtime switch to get wrong.
// Both flavours come out of the ONE terser pass above — the split is pure concatenation, which is why a second bundle
// costs ~1s.
//
//   fizzygum-boot-sw-min.js      det-trig + the FULL SWCanvas engine + SW3D + boot
//                                -> worldWithSystemTestHarness.html, index-sw.html
//   fizzygum-boot-native-min.js  boot only (the 3D vendor rides with its part)
//                                -> index.html
//
// window.SWCanvas must exist before boot() runs, hence the prepend rather than a second <script>.
// IMPORTANT: the minified vendor files end with a "//# sourceMappingURL=..." line comment and no trailing newline; the
// "\n;\n" separators terminate it and defend against ASI between each unit.
function bundles(profile) {
  if (profile.shipsSWCanvasEntry) {
    const sw = BUILD_PATH + '/js/fizzygum-boot-sw-min.js';
    out('assembling the SW boot bundle (deterministic-trig + SWCanvas + SW3D + boot)...\n');
    // DETERMINISM: install engine-independent sin/cos/tan/atan2/asin/acos (a pure-arithmetic fdlibm port — only
    // +,-,*,/ and sqrt, all IEEE-754-exact) over Math.* BEFORE anything renders, so SWCanvas's rotate()/arc()/
    // round-joins rasterize bit-identically on every JS engine. Without it the platform Math transcendentals differ by
    // ~1 ULP across engines (e.g. Safari's JavaScriptCore vs Chrome's V8 disagree on ~10-20% of values), which shifts
    // curved/rotated SWCanvas output a pixel or two and breaks the exact SHA-256 reference match (axis-aligned,
    // trig-free content is unaffected). Measured: it matches native V8 pixel-for-pixel across the suite, so it is a
    // drop-in. It rides ONLY on this bundle: it exists for SWCanvas's cross-engine byte-exactness, and the native
    // page's pixels are not reference-matched.
    // ⚠ THE INSTALL LINE IS LOAD-BEARING FOR src/, NOT JUST FOR SWCANVAS. The rotation math in TransformSpec._cosSin
    // and HandleWdgt._pointerAngleToTargetAnchorDegrees calls Math.cos/sin/atan2, so on THESE pages — and only these —
    // those calls resolve to the fdlibm port, which is what makes rotated composites cross-engine byte-identical on the
    // reference-matched pages. It runs before any class source compiles, so no widget can ever observe the un-patched
    // Math. Do not move it later. See runtime-prelude/deterministic-trig.js and src/macros/MACRO-PATTERNS.md.
    if (catInto(sw, 'w', READS_BY_NAME.detTrig)) buildFailed('assembling the SW boot bundle (the deterministic trig)');
    append(sw, '\n;try { DetTrig.install(Math); } catch (e) {}\n;\n');
    if (catInto(sw, 'a', READS_BY_NAME.swcanvas)) buildFailed('assembling the SW boot bundle (SWCanvas)');
    append(sw, '\n;\n');
    // SW3D — the software-3D userland engine (examples/sw3d.js), bundled UNMINIFIED right after SWCanvas so
    // window.SW3D exists at boot. It reads SWCanvas.Core.* lazily (only inside makeEngine at render time), so loading
    // it after SWCanvas is sufficient.
    if (catInto(sw, 'a', READS_BY_NAME.sw3d)) buildFailed('assembling the SW boot bundle (SW3D)');
    append(sw, '\n;\n');
    if (catInto(sw, 'a', BOOT_MIN)) buildFailed('assembling the SW boot bundle (the boot code)');
    out('... done assembling the SW boot bundle\n');
  }
  // The native page paints its 2D through the platform canvas; fizzytiles' software 3D (SW3D and the sliver of
  // SWCanvas it needs) arrives with its part (buildSystem/parts.json names it in fizzytiles' "vendor" list, build.js
  // writes it for the flavours that ship that part, PartsRegistry injects it before the part's sources — and skips it
  // on the SW pages, whose bundle already carries the full engine and SW3D).
  // NO det-trig here, deliberately (owner call 2026-07-30). This page's pixels are not reference-matched, so its
  // rotations do not need to be cross-engine reproducible — platform Math trig is what we want. That is SAFE because no
  // source names `DetTrig`: the two rotation-math sites (TransformSpec._cosSin,
  // HandleWdgt._pointerAngleToTargetAnchorDegrees) call Math.cos/sin/atan2, which resolve to whatever the page
  // installed — the fdlibm port on the SW pages above, the platform's own trig here. Anything that reached for the
  // global by name would throw `DetTrig is not defined` the moment a window was rotated;
  // ../Fizzygum-tests/scripts/smoke-boot-headless.js rotates a widget on this page to keep that honest.
  out('assembling the native boot bundle (boot only — the 3D vendor rides with its part)...\n');
  if (catInto(BUILD_PATH + '/js/fizzygum-boot-native-min.js', 'w', BOOT_MIN)) buildFailed('assembling the native boot bundle');
  out('... done assembling the native boot bundle\n');
  // The bare minified boot JS is an intermediate, never an entry page's bundle.
  run('rm', [BOOT_MIN]);
}

// The vendored SWCanvas font assets (metrics + positioning bundles, and the wrapped atlas .js if vendored), so the
// SWCanvas text backend can load them at runtime over file://. These are font DATA, never embedded in a bundle. ONLY an
// SWCanvas entry page can use them, so a native-only tree does not carry them — that is ~90 MB not deployed.
// Populated by scripts/vendor-swcanvas-fonts.sh.
// ⚠ BOTH DIRECTIONS LIVE HERE, and the removal is not redundant: the tree is shared across flavours and font-assets/
// SURVIVES the clean (unlike js/, icons/ and *.html, which are wiped), so a native-only build following a full one
// would otherwise inherit ~90 MB of font data no page in it can load.
// Copied AFRESH: a copy over the previous one only adds and overwrites, so a font deleted from the source would still
// be served from the tree (and the record of the inputs would say it is gone). Each top-level entry is copied whole,
// as `cp -R font-assets/*` copied them: a top-level dot entry is not.
function fonts(profile) {
  if (profile.shipsSWCanvasEntry) {
    if (!isDirectory('font-assets')) return;
    out('copying SWCanvas font assets...\n');
    removeTree(BUILD_PATH + '/font-assets', 'removing the previous font assets');
    if (run('mkdir', ['-p', BUILD_PATH + '/font-assets'])) buildFailed('making the font-assets directory');
    if (run('cp', ['-R', ...glob('font-assets', ''), BUILD_PATH + '/font-assets/'])) buildFailed('copying the SWCanvas font assets');
    out('... done copying SWCanvas font assets\n');
  } else {
    removeTree(BUILD_PATH + '/font-assets', 'removing the font assets no page here loads');
  }
}

// Code that can be loaded after a pre-compiled world has started. EVERY boot loads only the minified twin
// (globalFunctions.coffee fetches js/src/<name>-min.js), on the precompiled path as much as the compile-at-boot one --
// so the unminified .js is a pure INTERMEDIATE and is compiled into the scratch dir, never into the tree. js/src/ is
// made here (terser will not create its output's directory). The scripts are the shipping parts' `bootScripts`
// (buildSystem/parts.json), each compiled on its own. ⚠ dependencies-finding (the class LOAD ORDER, read from the
// source text: the reflective layer's) is built for EVERY profile even so, and dropped later for the ones that cannot
// use it: the pre-compile driver harvests the image by booting this tree in COMPILE-AT-BOOT mode, which runs that layer
// and fetches this file. Skipping it here made a lean build hang until puppeteer's protocol timeout, with no error
// naming the missing file (measured).
function bootScripts({ COFFEE, TERSER }, scripts) {
  if (run('mkdir', ['-p', JSSRC_SCRATCH])) buildFailed('making the boot scripts scratch directory');
  if (run('mkdir', ['-p', BUILD_PATH + '/js/src'])) buildFailed('making the js/src directory');
  for (const script of scripts) {
    const name = path.basename(script, '.coffee');
    if (run(COFFEE, ['-b', '-c', '-o', JSSRC_SCRATCH + '/', script])) buildFailed('compiling the boot script ' + script);
    if (run(TERSER, ['--compress', '--output', `${BUILD_PATH}/js/src/${name}-min.js`, '--', `${JSSRC_SCRATCH}/${name}.js`])) {
      buildFailed('minifying the boot script ' + script);
    }
  }
}

// The pre-compiled stub (`window.preCompiled = false`: compile-at-boot), which a precompiled profile replaces below;
// then the scratch dir goes. (The entry pages, the vendored js/libs files and the assets/icons images are written by
// build.js, from src/index.html and from the "assets" list of whichever PART owns each one.)
function stubAndScratch() {
  out('copying pre-compiled file\n');
  if (run('cp', [READS_BY_NAME.preCompiledStub, BUILD_PATH + '/js/pre-compiled.js'])) buildFailed('copying the pre-compiled stub');
  out('... done\n');
  out('... done copying icon files\n');
  out('cleanup unneeded files\n');
  run('rm', ['-rdf', SCRATCH_PATH]);
  out('...done\n');
}

// ---- form: precompiled ----
// Does this profile ship a PRE-COMPILED image instead of compiling the classes in the browser? The image is generated
// HERE, while js/pre-compiled.js is still the stub — compile-at-boot is exactly the mode that builds the image. The
// driver lives in the tests repo because Node resolves require('puppeteer') from the SCRIPT's directory; it runs from
// there whatever this build's cwd. Then the image is minified in place.
// sources: "none" -- the appliance artifact. The class source text was a build INPUT: the driver harvested the image by
// booting this very tree in compile-at-boot mode and compiling every source. Now that the image exists, the text does
// not ship -- ~40% of the tree, and with it the ability to inspect and rewrite the system (lib/profile.js
// SOURCES_POLICIES). This is a DERIVED consequence of the policy, not a list of files to delete: one directory, and
// what goes in it was never enumerated here.
// ⚠ The parts manifest compiled into the boot bundle still NAMES those batch files, because it was written before the
// driver ran and lives inside a minified bundle. Nothing in this artifact reads the list -- globalFunctions skips the
// whole reflective layer under "none", and a lazy part (the other reader) is refused with this policy by
// lib/profile.js, precisely because a lazy part arrives AS SOURCE and so could never load here.
// ⚠ EVERYTHING THE REFLECTIVE LAYER NEEDS IS AN INPUT TO THIS STEP, so nothing it needs can be skipped earlier -- it can
// only be dropped here, once the image exists. Both of these were learned by watching a lean build fail: skip the
// source text and the driver harvests nothing; skip dependencies-finding and the generation boot hangs on a 404 until
// puppeteer times out.
function preCompile({ TERSER }, profile) {
  if (profile.form !== 'precompiled') return;
  out('generating the pre-compiled file headlessly. this might take a few seconds...\n');
  if (run('node', [path.join('scripts', 'generate-pre-compiled-headless.js')], { cwd: '../Fizzygum-tests' })) {
    err('!!!!!!!!!!! error: pre-compiled generation failed\n');
    throw new Stop(1);
  }
  const image = BUILD_PATH + '/js/pre-compiled.js', minified = BUILD_PATH + '/js/pre-compiled-min.js';
  if (run(TERSER, ['--compress', '--mangle', '--output', minified, '--', image])) buildFailed('minifying the pre-compiled image');
  if (run('mv', [minified, image])) buildFailed('moving the minified pre-compiled image into place');
  if (profile.sources === 'none') {
    out("sources policy 'none': dropping the reflective layer (it was only an input to the pre-compiled image)\n");
    removeTree(BUILD_PATH + '/js/coffeescript-sources', 'dropping the class sources (sources: none)');
    // named here as boot fetches it (the coverage gate holds boot's fetches to parts.json's bootScripts, not this
    // line): a file that is not there was renamed, and the lean tree would ship the layer's script under its new name,
    // so this lean build fails here instead
    const layer = BUILD_PATH + '/js/src/dependencies-finding-min.js';
    if (!isFile(layer)) buildFailed("dropping the reflective layer's boot script (js/src/dependencies-finding-min.js was not built: renamed?)");
    if (run('rm', ['-f', layer])) buildFailed("dropping the reflective layer's boot script (sources: none)");
  }
}

// BUILD STAMP: written ONLY here, at the very end of a successful build, with the mtime of the start marker laid before
// the build read its first input, and with it the record of the inputs it read (Fizzygum/.latest-build-inputs, bound
// to this stamp by that start time). The runners refuse to run if the inputs are not, each, the one recorded (its
// mtime and size; one deleted, renamed, added or put back), or if the stamp or the record is missing -- so a build that
// didn't run / failed / ran from the wrong cwd, or whose inputs changed while or since it ran, can never be tested as
// if fresh. The inputs and the question: buildSystem/lib/build-inputs.js buildStaleness; the refusal:
// Fizzygum-tests/scripts/lib/assert-build-fresh.js.
function stampTree() {
  if (!isFile(START)) {
    bell();
    err('!!!!!!!!!!! error: could not write the build stamp (no .build-start: another build in this tree?)\n');
    throw new Stop(1);
  }
  if (run('mv', [RECORD + '.reading', RECORD])) buildFailed('recording the inputs this build read');
  if (run('touch', ['-r', START, STAMP])) buildFailed('writing the build stamp');
  run('rm', ['-f', START]);
}

function main(argv) {
  // always from Fizzygum/, whatever the caller's cwd: every path above is relative to it
  process.chdir(path.resolve(__dirname, '..'));
  // Ctrl-C: see reRaiseInterrupt
  process.on('SIGINT', () => {});
  const { noSyntaxCheck } = readArguments(argv);
  checkLayout();
  vendorEngine();
  startRecord();
  const tools = checkToolchain();
  const { profile, prelude, scripts } = readProfile(argv);
  clean();
  linkTests(profile);
  assemble(argv);
  runGates(argv, noSyntaxCheck, profile);
  bootSource(profile, prelude);
  minifyBoot(tools, buildVersion());
  bundles(profile);
  fonts(profile);
  bootScripts(tools, scripts);
  stubAndScratch();
  preCompile(tools, profile);
  stampTree();
  // for OSX: say build done
  bell();
  out('done!!!!!!!!!!!!\n');
  return 0;
}

module.exports = { READS_BY_NAME, BUILD_PATH, Stop, clean, removeTree, removeTestsLink, checkTree };

if (require.main === module) {
  try { process.exitCode = main(process.argv.slice(2)); } catch (e) {
    if (e instanceof Stop) process.exitCode = e.code;
    else { err(`run-build: ${(e && e.stack) || e}\n`); process.exitCode = 1; }
  }
}

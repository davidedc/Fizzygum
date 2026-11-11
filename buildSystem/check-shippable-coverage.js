#!/usr/bin/env node
'use strict';
/*
 * check-shippable-coverage.js — build-time guard: every directory of the compiled sources (src/ and the
 * tests repo's harness) that contains .coffee files must be CLAIMED BY A PART in buildSystem/parts.json, and
 * every src/boot file DECLARED by one (its bootPrelude or bootScripts).
 *
 * WHY THIS EXISTS
 * The shipped-file list is hand-maintained: it used to be a sequence of `glob("src/<dir>/*.coffee")`
 * calls inside build.py, and since arc 4 it is the `dirs` lists in buildSystem/parts.json. Either
 * way, add a NEW src/ subdirectory and it ships NOTHING until someone remembers to name it — the
 * build still exits 0, and the syntax gate (buildSystem/check-coffee-syntax.js, which reads the
 * same --list-shippable set) silently skips the new dir too. The only symptom is a runtime
 * `<NewClass> is not defined` the first time something references a class in the forgotten dir —
 * this cost a red presuite in phase C1. This gate closes that gap by comparing "every .coffee file
 * the build could compile" against "what the partition says ships". The harness is held the same
 * way: parts.json names its directories one by one too, so a new harness subdirectory ships nothing.
 *
 * Since arc 4, --list-shippable is FLAVOUR-INDEPENDENT (it lists the whole partition, not what one
 * build flavour keeps), which is what this gate and the syntax gate both want: coverage of the
 * partition is not a property of a flavour, and a syntax error in a file only the dev build carries
 * is still a syntax error. build.py additionally fails outright if two parts claim the same
 * directory, so "claimed by a part" means "claimed by exactly one part".
 *
 * HOW IT WORKS
 * 1. SHIPPED set: `python3 buildSystem/build.py --list-shippable <forwarded args>` — the exact
 *    same source of truth buildSystem/check-coffee-syntax.js uses, so this gate can't drift
 *    from what the build actually wraps-as-text and compiles in-browser.
 * 2. FULL set: lib/source-files.js compiledFiles — every .coffee file under src/ and the harness, the
 *    one definition every gate reads (a dot directory, a node_modules or a dot file included, so a file
 *    there FAILS here as UNSHIPPED; a symlink anywhere is refused, SOURCE_TREE_MALFORMED). Each is named
 *    as --list-shippable spells it: `src/…`, and `../Fizzygum-tests/Automator-and-test-harness-src/…`.
 * 3. BOOT set: `python3 buildSystem/build.py --list-boot <forwarded args>` — every src/boot file a part declares
 *    (its `bootPrelude`: the boot bundle's pieces, in order; its `bootScripts`: the scripts boot fetches by name).
 *    Boot files are not classes, so they are not in --list-shippable (the syntax and part-edges gates compile what
 *    that lists the class way), but they are declared all the same, in buildSystem/parts.json, and build.py fails a
 *    declared piece that does not exist.
 * 4. unshipped = FULL − SHIPPED − BOOT. Any survivor FAILS the check: a .coffee file in a directory no part claims,
 *    or a src/boot file no part declares, ships nothing (UNSHIPPED).
 * 5. BOOT FETCHES: boot fetches each boot script by name (`js/src/<name>-min.js`), so a rename on one side keeps every
 *    gate green and 404s at every boot. Each name a boot file's CODE spells that way (its comments blanked, so a comment
 *    naming an old name neither satisfies nor trips this) must be a bootScript of the file's OWN part
 *    (BOOT_FETCH_UNDECLARED, naming file:line), and each bootScript must be fetched so by its part's boot files
 *    (BOOT_SCRIPT_UNFETCHED). A name built at run time is invisible, and reads as no fetch.
 *
 * Run from the Fizzygum/ repo root (build_it_please.sh does this):
 *   node ./buildSystem/check-shippable-coverage.js [--src=DIR] [--tests-repo=DIR] [build flags...]
 * The build flags go to build.py (which refuses one it does not know); --src= and --tests-repo= check other trees (a
 * copy carrying a plant), handed to build.py's listings too. That its rule BITES is proven on every build by
 * check-shippable-coverage-selftest.js.
 */

const path = require('path');
const { execFileSync } = require('child_process');
const { compiledFiles, sourceRoots, sourceName, SOURCE_RAILS, HARNESS_DIR } = require('./lib/source-files');
const { bootPieces, onDiskIn } = require('./lib/boot-pieces');
const { coffeeMask } = require('./lib/coffee-mask');
const fs = require('fs');
const rules = require('./lib/gate-rules').forGate(__filename);

const REPO = process.cwd(); // build_it_please.sh runs us from Fizzygum/
const ARGV = process.argv.slice(2);
const ROOTS = sourceRoots(ARGV, 'check-shippable-coverage');
// a rail given goes to build.py's listing as the resolved tree; every other argument is a build flag
const isRail = (a) => SOURCE_RAILS.some((r) => a.startsWith(r));
const BUILD_ARGS = [...ARGV.filter((a) => !isRail(a)),
  ...(ARGV.some((a) => a.startsWith('--src=')) ? ['--src=' + ROOTS.src] : []),
  ...(ARGV.some((a) => a.startsWith('--tests-repo=')) ? ['--tests-repo=' + ROOTS.testsRepo] : [])];
// how --list-shippable spells a harness file (parts.json names the harness's directories from Fizzygum/)
const HARNESS_LISTED = '../Fizzygum-tests/' + HARNESS_DIR + '/';

function fail(msg) { console.error('check-shippable-coverage: ' + msg); process.exit(2); }

// a build.py listing (one path per line), or an operational failure
function listing(flag) {
  let out;
  try {
    out = execFileSync('python3', ['-B', 'buildSystem/build.py', flag, ...BUILD_ARGS],
      { cwd: REPO, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024 });
  } catch (e) {
    fail('could not get build.py ' + flag + ': ' + e.message);
  }
  const set = new Set(out.split('\n').map(function (s) { return s.trim(); }).filter(Boolean));
  if (!set.size) fail('build.py ' + flag + ' returned no files');
  return set;
}

// ---- 1. the SHIPPED set (the partition's classes) and the BOOT set (the parts' declared src/boot files), straight
// from build.py (the single source of truth for both) ----
const shippedSet = listing('--list-shippable');
let pieces;
try { pieces = bootPieces(BUILD_ARGS); } catch (e) { fail('could not get build.py --list-boot: ' + e.message); }
if (!pieces.length) fail('build.py --list-boot returned no files');
const bootSet = new Set(pieces.map((piece) => piece.file));

// ---- 2. the FULL set: every .coffee file the build could compile, named as --list-shippable names it ----
let fullRel;
try {
  fullRel = compiledFiles(ROOTS).map(function (file) {
    const name = sourceName(file, ROOTS, 'src/');
    return name.startsWith('harness/') ? HARNESS_LISTED + name.slice('harness/'.length) : name;
  });
} catch (e) {
  fail(e.message);
}

// ---- 3. unshipped = FULL − SHIPPED − BOOT ----
const unshipped = fullRel.filter(function (rel) { return !shippedSet.has(rel) && !bootSet.has(rel); });

// ---- 3b. boot's by-name fetches against the declared boot scripts (header, 5.) ----
// every `js/src/<name>-min.js` a boot file's CODE names (its comments blanked: lib/coffee-mask.js), with its line
const FETCH = /js\/src\/([A-Za-z0-9_-]+)-min\.js/g;
const fetches = [];   // { name, at, part }
for (const piece of pieces) {
  let text;
  try { text = fs.readFileSync(onDiskIn(ROOTS.src, piece), 'utf8'); } catch (e) { fail('cannot read ' + piece.file + ': ' + e.message); }
  coffeeMask(text, piece.file).forEach((line, i) => {
    for (const m of line.code.matchAll(FETCH)) fetches.push({ name: m[1], at: piece.file + ':' + (i + 1), part: piece.part });
  });
}
const scriptOf = (piece) => path.posix.basename(piece.file, '.coffee');
const declaredScripts = pieces.filter((piece) => piece.kind === 'script');
const fetchProblems = [];
for (const f of fetches) {
  if (!declaredScripts.some((piece) => piece.part === f.part && scriptOf(piece) === f.name)) {
    fetchProblems.push(rules.fired('BOOT_FETCH_UNDECLARED', '  BOOT_FETCH_UNDECLARED ' + f.at + ' fetches js/src/' + f.name +
      '-min.js, which no bootScript of its own part (' + f.part + ') declares'));
  }
}
for (const piece of declaredScripts) {
  if (!fetches.some((f) => f.part === piece.part && f.name === scriptOf(piece))) {
    fetchProblems.push(rules.fired('BOOT_SCRIPT_UNFETCHED', '  BOOT_SCRIPT_UNFETCHED ' + piece.file + ' (a bootScript of ' + piece.part +
      ') is fetched by no code line of its part\'s boot files as js/src/' + scriptOf(piece) + '-min.js'));
  }
}

// ---- 4. report + exit ----
if (fetchProblems.length) {
  console.error('check-shippable-coverage: boot fetches its scripts by name, and the names disagree with parts.json\'s bootScripts:');
  for (const line of fetchProblems) console.error(line);
  console.error('Fix: name each script in the same part\'s bootScripts and fetch it as a literal js/src/<name>-min.js in code ' +
    '(a name built at run time is invisible here, and reads as no fetch) — a rename on one side only is a 404 at every boot.');
}
if (unshipped.length) {
  unshipped.sort();
  const dirs = new Set(unshipped.map(function (rel) { return path.posix.dirname(rel); }));
  console.error('check-shippable-coverage: ' + unshipped.length + ' .coffee file(s) of the compiled sources '
    + 'are NOT covered by build.py\'s --list-shippable or --list-boot output:');
  for (const rel of unshipped) console.error(rules.fired('UNSHIPPED', '  UNSHIPPED ' + rel));
  console.error('');
  console.error('Fix: claim each offending directory below in the part it belongs to (its "dirs" in '
    + 'buildSystem/parts.json; a part\'s dirs are not recursive) — or, for a src/boot file, declare it in a part\'s '
    + '"bootPrelude" (a boot-bundle piece, in order) or "bootScripts" (a script boot fetches by name) — then re-run the '
    + 'build:');
  for (const dir of Array.from(dirs).sort()) console.error('  ' + dir);
}
if (unshipped.length || fetchProblems.length) process.exit(1);

console.log('shippable-coverage check: ' + fullRel.length + ' .coffee files under src/ and the harness, all covered '
  + '— 0 gap(s); ' + fetches.length + ' boot fetch(es) of ' + declaredScripts.length + ' declared boot script(s), all agreeing');
process.exit(0);

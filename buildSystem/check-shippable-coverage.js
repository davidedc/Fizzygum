#!/usr/bin/env node
'use strict';
/*
 * check-shippable-coverage.js — build-time guard: every directory of the compiled sources (src/ and the
 * tests repo's harness) that contains .coffee files must be CLAIMED BY A PART in buildSystem/parts.json.
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
 * 3. unshipped = FULL − SHIPPED − ALLOWLIST. Any survivor FAILS the check.
 *
 * THE ALLOWLIST (ONE prefix, verified legitimate on a clean tree — it is not a real coverage gap,
 * so excluding it is what makes a clean tree PASS):
 *   - src/boot/**  is not part material at all. Boot files are not text-wrapped classes:
 *     build_it_please.sh `cat`s them into the boot bundle and `coffee -c` compiles them BY NAME,
 *     one at a time. That is a real hand-maintained shipped list too — it just lives in the shell
 *     script rather than in the partition, which puts it out of scope for THIS gate. parts.json
 *     says the same thing in core's own comment. Empirically verified: on a clean tree,
 *     --list-shippable omits exactly the files under src/boot/** and nothing else.
 * (src/video-player/** was the second entry until arc 4 made it a PART — see ALLOWLIST_PREFIXES.)
 * An entry is held to what it exempts: a prefix that exempts no unshipped file — its path is gone, or
 * a part now claims everything under it — FAILS as stale (STALE_ALLOWLIST_ENTRY), since left in place it
 * would silently hide the next real gap under that path.
 *
 * Any OTHER directory must appear, in full, in --list-shippable's output; a single
 * uncovered file (a new dir, or a dir no part claims) fails the build.
 *
 * SAFE FAILURE DIRECTION: worst case the allowlist is too narrow and the gate cries wolf on a
 * legitimately-different-but-covered dir (operational annoyance, fixed once by extending the
 * allowlist with a reason) — it can never SILENTLY mask a real uncovered dir, which is the
 * failure mode this gate exists to close.
 *
 * Run from the Fizzygum/ repo root (build_it_please.sh does this):
 *   node ./buildSystem/check-shippable-coverage.js [--src=DIR] [--tests-repo=DIR] [build flags...]
 * The build flags go to build.py (which refuses one it does not know); --src= and --tests-repo= check other trees (a
 * copy carrying a plant), handed to build.py's listing too. That both rules BITE is proven on every build by
 * check-shippable-coverage-selftest.js.
 */

const path = require('path');
const { execFileSync } = require('child_process');
const { compiledFiles, sourceRoots, sourceName, SOURCE_RAILS, HARNESS_DIR } = require('./lib/source-files');
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

// hard-coded, commented allowlist — see header for why the one remaining prefix is legitimate (and why a
// prefix that exempts nothing fails as stale).
// src/video-player/ used to be here (it shipped only behind --includeVideoPlayer, so it was
// correctly absent from a default build's list). It is now the 'video-player' PART, so the
// partition claims it in every flavour and --list-shippable always names it: the exemption became
// unnecessary, and keeping it would have been a hole that hid a real gap in that directory.
const ALLOWLIST_PREFIXES = [
  'src/boot/',          // not part material: build_it_please.sh cats/compiles these BY NAME
];

function isAllowlisted(relPath) {
  return ALLOWLIST_PREFIXES.some(function (prefix) { return relPath.indexOf(prefix) === 0; });
}

// ---- 1. the SHIPPED set, straight from build.py (single source of truth) ----
let shippedSet;
try {
  const out = execFileSync('python3', ['-B', 'buildSystem/build.py', '--list-shippable', ...BUILD_ARGS],
    { cwd: REPO, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024 });
  shippedSet = new Set(out.split('\n').map(function (s) { return s.trim(); }).filter(Boolean));
} catch (e) {
  fail('could not get the shippable file list from build.py: ' + e.message);
}
if (!shippedSet.size) fail('build.py --list-shippable returned no files');

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

// ---- 3. unshipped = FULL − SHIPPED − ALLOWLIST ----
const unshipped = fullRel.filter(function (rel) {
  return !shippedSet.has(rel) && !isAllowlisted(rel);
});
// an allowlist prefix that exempts no unshipped file is stale (header)
const staleAllowlist = ALLOWLIST_PREFIXES.filter(function (prefix) {
  return !fullRel.some(function (rel) { return !shippedSet.has(rel) && rel.indexOf(prefix) === 0; });
});
if (staleAllowlist.length) {
  for (const prefix of staleAllowlist) {
    console.error(rules.fired('STALE_ALLOWLIST_PREFIX', 'check-shippable-coverage: STALE_ALLOWLIST_ENTRY ALLOWLIST_PREFIXES \'' + prefix + '\' — it exempts no '
      + 'unshipped .coffee file (no such path, or a part claims everything under it), so it would only hide the next '
      + 'real gap there: delete the entry'));
  }
}

// ---- 4. report + exit ----
if (unshipped.length) {
  unshipped.sort();
  const dirs = new Set(unshipped.map(function (rel) { return path.posix.dirname(rel); }));
  console.error('check-shippable-coverage: ' + unshipped.length + ' .coffee file(s) of the compiled sources '
    + 'are NOT covered by build.py\'s --list-shippable output:');
  for (const rel of unshipped) console.error(rules.fired('UNSHIPPED', '  UNSHIPPED ' + rel));
  console.error('');
  console.error('Fix: claim each offending directory below in the part it belongs to (its "dirs" in '
    + 'buildSystem/parts.json; a part\'s dirs are not recursive), then re-run the build:');
  for (const dir of Array.from(dirs).sort()) console.error('  ' + dir);
  console.error('');
  console.error('(A directory built by another mechanism — like src/boot/, which build_it_please.sh compiles by name — '
    + 'goes on the ALLOWLIST_PREFIXES list at the top of this script, with a reason.)');
  process.exit(1);
}
if (staleAllowlist.length) process.exit(1);

console.log('shippable-coverage check: ' + fullRel.length + ' .coffee files under src/ and the harness, all covered '
  + '(or allowlisted) — 0 gap(s)');
process.exit(0);

#!/usr/bin/env node
'use strict';
/*
 * check-shippable-coverage.js — build-time guard: every src/ subdirectory that contains
 * .coffee files must be CLAIMED BY A PART in buildSystem/parts.json.
 *
 * WHY THIS EXISTS
 * The shipped-file list is hand-maintained: it used to be a sequence of `glob("src/<dir>/*.coffee")`
 * calls inside build.py, and since arc 4 it is the `dirs` lists in buildSystem/parts.json. Either
 * way, add a NEW src/ subdirectory and it ships NOTHING until someone remembers to name it — the
 * build still exits 0, and the syntax gate (buildSystem/check-coffee-syntax.js, which reads the
 * same --list-shippable set) silently skips the new dir too. The only symptom is a runtime
 * `<NewClass> is not defined` the first time something references a class in the forgotten dir —
 * this cost a red presuite in phase C1. This gate closes that gap by comparing "every .coffee file
 * that actually exists under src/" against "what the partition says ships".
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
 * 2. FULL set: every .coffee file that actually exists under src/ (recursive fs walk).
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
 *
 * Any OTHER src/ subdirectory must appear, in full, in --list-shippable's output; a single
 * uncovered file (a new dir, or a dir no part claims) fails the build.
 *
 * SAFE FAILURE DIRECTION: worst case the allowlist is too narrow and the gate cries wolf on a
 * legitimately-different-but-covered dir (operational annoyance, fixed once by extending the
 * allowlist with a reason) — it can never SILENTLY mask a real uncovered dir, which is the
 * failure mode this gate exists to close.
 *
 * Run from the Fizzygum/ repo root (build_it_please.sh does this):
 *   node ./buildSystem/check-shippable-coverage.js [build flags...]
 */

const path = require('path');
const fs = require('fs');
const { execFileSync } = require('child_process');

const REPO = process.cwd(); // build_it_please.sh runs us from Fizzygum/

function fail(msg) { console.error('check-shippable-coverage: ' + msg); process.exit(2); }

// hard-coded, commented allowlist — see header for why the one remaining prefix is legitimate.
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
  const out = execFileSync('python3', ['-B', 'buildSystem/build.py', '--list-shippable', ...process.argv.slice(2)],
    { cwd: REPO, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024 });
  shippedSet = new Set(out.split('\n').map(function (s) { return s.trim(); }).filter(Boolean));
} catch (e) {
  fail('could not get the shippable file list from build.py: ' + e.message);
}
if (!shippedSet.size) fail('build.py --list-shippable returned no files');

// ---- 2. the FULL set: every .coffee file that actually exists under src/ ----
function walkCoffeeFiles(dir, out) {
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch (e) {
    fail('could not read directory "' + dir + '": ' + e.message);
  }
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walkCoffeeFiles(full, out);
    } else if (entry.isFile() && entry.name.endsWith('.coffee')) {
      out.push(full);
    }
  }
  return out;
}

const srcDir = path.join(REPO, 'src');
if (!fs.existsSync(srcDir)) fail('no "src" directory found under "' + REPO + '"');
const fullFiles = walkCoffeeFiles(srcDir, []);
if (!fullFiles.length) fail('found zero .coffee files under src/ — something is very wrong');

// normalise to REPO-relative, forward-slash paths, e.g. "src/apps/DashboardsApp.coffee",
// matching the format build.py --list-shippable prints.
const fullRel = fullFiles.map(function (abs) {
  return path.relative(REPO, abs).split(path.sep).join('/');
});

// ---- 3. unshipped = FULL − SHIPPED − ALLOWLIST ----
const unshipped = fullRel.filter(function (rel) {
  return !shippedSet.has(rel) && !isAllowlisted(rel);
});

// ---- 4. report + exit ----
if (unshipped.length) {
  unshipped.sort();
  const dirs = new Set(unshipped.map(function (rel) { return path.posix.dirname(rel); }));
  console.error('check-shippable-coverage: ' + unshipped.length + ' shipped .coffee file(s) under src/ '
    + 'are NOT covered by build.py\'s --list-shippable output:');
  for (const rel of unshipped) console.error('  UNSHIPPED ' + rel);
  console.error('');
  console.error('Fix: add glob("src/<dir>/*.coffee") to buildSystem/build.py\'s shippable-source list '
    + '(~lines 191-233) for each offending directory below, then re-run the build:');
  for (const dir of Array.from(dirs).sort()) console.error('  ' + dir);
  console.error('');
  console.error('(If the directory is DELIBERATELY conditional or built by a different mechanism — like '
    + 'src/video-player/ behind --includeVideoPlayer, or src/boot/ which build_it_please.sh compiles '
    + 'directly — add it to the ALLOWLIST_PREFIXES list at the top of this script, with a reason.)');
  process.exit(1);
}

console.log('shippable-coverage check: ' + fullRel.length + ' .coffee files under src/, all covered '
  + '(or allowlisted) — 0 gap(s)');
process.exit(0);

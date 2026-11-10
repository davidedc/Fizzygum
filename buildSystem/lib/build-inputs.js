'use strict';
// build-inputs.js — is the last build stale? The one answer: what a build's OUTPUT is made from, and when the last
// build read it. The runners' guard (Fizzygum-tests/scripts/lib/assert-build-fresh.js) and the reports that state
// freshness ask it.
//
// THE INPUTS are the FILES the build names, never the directories that hold them (a directory also holds what the
// build never reads — a subsystem's CLAUDE.md, an editor's swap file, a Finder .DS_Store, a gate's vendored parser — and
// any churn there would read as a stale build):
//   - every compiled source (lib/source-files.js compiledFiles: src's and the harness's .coffee, the boot files among
//     them) and src/index.html, which every entry page is written from;
//   - the build itself: build_it_please.sh, build.py, buildProfile.py, parts.json and the profiles;
//   - what the partition declares a part ships besides its sources: each `assets` source and each `vendor` piece;
//   - what build_it_please.sh names itself (SHELL_INPUTS below — the SWCanvas bundle's pieces and the pre-compiled stub),
//     and every file under font-assets/ (copied whole when an entry renders through SWCanvas).
// Not inputs: the gates (they judge the output, they do not shape it, so a gate edit never makes a build stale), the
// pre-compile driver (it shapes only a precompiled profile's image, which no runner tests; `fg homepage` runs it) and
// the videos `--includeVideos` copies from ../Fizzygum-videos-public (outside the repos).
// ⚠ A DELETED input is not seen: no surviving file's mtime moves (BACKLOG, "A deleted input leaves a build reading FRESH").
//
// THE STAMP: build_it_please.sh lays `latest/.build-start` before it reads any input (once the vendored SWCanvas a fresh
// clone fetches is in place), removes `latest/.build-stamp` at its first write to the tree, and gives the stamp that
// marker's mtime as its very last act. So a build that did not complete leaves NO stamp, and an input edited while the
// build ran reads newer than it.
//
// newestBuildInput() -> { newest, newestFile } (a file that does not exist is skipped: a declared one the build would
// fail on, an absent tests repo); lastBuildTime() -> the stamp's mtime, or undefined when no build completed. A
// listing that fails throws.

const fs = require('fs');
const path = require('path');
const { compiledFiles } = require('./source-files');

const FIZZYGUM = path.resolve(__dirname, '..', '..');
const STAMP = path.resolve(FIZZYGUM, '..', 'Fizzygum-builds', 'latest', '.build-stamp');   // build_it_please.sh writes it
const BUILD_FILES = ['build_it_please.sh', 'buildSystem/build.py', 'buildSystem/buildProfile.py', 'buildSystem/parts.json',
  'src/index.html'];
// the files build_it_please.sh reads by name, outside the partition: a rename there is a rename here (a name that no
// longer exists is skipped, and that input goes unwatched)
const SHELL_INPUTS = ['runtime-prelude/deterministic-trig.js', 'vendor/swcanvas/swcanvas.min.js', 'vendor/swcanvas/sw3d.js',
  'auxiliary files/pre-compiled.js'];
const INPUT_TREES = ['buildSystem/profiles', 'font-assets'];   // every file under them

function declaredPayloads() {
  const parts = JSON.parse(fs.readFileSync(path.join(FIZZYGUM, 'buildSystem', 'parts.json'), 'utf8')).parts;
  const files = [];
  for (const [name, part] of Object.entries(parts)) {
    if (name.startsWith('//')) continue;
    for (const asset of part.assets || []) files.push(asset[0]);
    for (const payload of part.vendor || []) files.push(...payload.concat);
  }
  return files;
}

function filesUnder(dir) {
  const out = [];
  const walk = (d) => {
    let entries;
    try { entries = fs.readdirSync(d, { withFileTypes: true }); } catch (e) { if (e.code === 'ENOENT') return; throw e; }
    for (const e of entries) {
      if (e.name.startsWith('.')) continue;                    // .DS_Store and kin: never read by the build
      const p = path.join(d, e.name);
      if (e.isDirectory()) walk(p); else if (e.isFile()) out.push(p);
    }
  };
  walk(dir);
  return out;
}

function newestBuildInput() {
  const files = [
    ...compiledFiles(),
    ...[...BUILD_FILES, ...SHELL_INPUTS, ...declaredPayloads()].map((f) => path.join(FIZZYGUM, f)),
    ...INPUT_TREES.flatMap((d) => filesUnder(path.join(FIZZYGUM, d))),
  ];
  let newest = 0, newestFile;
  for (const file of files) {
    let mtime;
    try { mtime = fs.statSync(file).mtimeMs; } catch (_) { continue; }
    if (mtime > newest) { newest = mtime; newestFile = file; }
  }
  return { newest, newestFile };
}

function lastBuildTime() {
  try { return fs.statSync(STAMP).mtimeMs; } catch (_) { return undefined; }
}

module.exports = { newestBuildInput, lastBuildTime };

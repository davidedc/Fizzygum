'use strict';
// not-a-gate: the build launches it (--record) only to RECORD what it reads; it judges nothing, and a listing it cannot
// make throws, which the build reports as a step that failed (run-build.js buildFailed).
// build-inputs.js — is the last build stale? The one answer: what a build's OUTPUT is made from, as each of those files
// was when the last build began reading it. Every reader asks buildStaleness(): the runners' guard
// (Fizzygum-tests/scripts/lib/assert-build-fresh.js), the single runner's capture-path warning and torture's report.
//
// THE INPUTS are the FILES the build names, never the directories that hold them (a directory also holds what the
// build never reads — a subsystem's CLAUDE.md, an editor's swap file, a Finder .DS_Store, a vendored library's README — and
// any churn there would read as a stale build):
//   - every compiled source (lib/source-files.js compiledFiles: src's and the harness's .coffee, the boot files among
//     them) and src/index.html, which every entry page is written from;
//   - the build itself: build_it_please.sh, run-build.js, build.js, lib/profile.js, parts.json and the profiles (`*.json`), and
//     package-lock.json, which pins the CoffeeScript and the terser the build runs (an upgrade there is new output);
//   - what the partition declares a part ships besides its sources: each `assets` source and each `vendor` piece;
//   - what the build names itself (run-build.js READS_BY_NAME — the SWCanvas bundle's pieces and the pre-compiled stub),
//     and every file under font-assets/ (copied whole when an entry renders through SWCanvas).
// Not inputs: the gates (they judge the output, they do not shape it, so a gate edit never makes a build stale) and the
// pre-compile driver (it shapes only a precompiled profile's image, which no runner tests; `fg homepage` runs it).
//
// THE RECORD: the build (run-build.js) lays `latest/.build-start` before it reads any input (once the vendored SWCanvas a
// fresh clone fetches is in place) and records, with it, every input with its mtime and size (`--record`, headed by the
// marker's own mtime); it removes the previous stamp and record at its first write to the tree, and promotes the record
// and gives the stamp the marker's mtime as its very last act. So a build that did not complete leaves neither, the
// record names the build it belongs to (its start time IS the stamp's), and an input deleted, renamed, added, edited
// (during the build or since) or put back with an older time is not the one recorded — which no comparison of times
// with the stamp could show for most of those. The record lives OUTSIDE the tree the build writes
// (`Fizzygum/.latest-build-inputs`, gitignored): the developer's input list is no part of an artifact, and anything
// derived from the inputs inside the tree would differ between any two builds `fg fingerprint` compares.
//
// buildInputs() -> every input file that exists, absolute, sorted (a declared file that does not exist is skipped: the
// build fails on it, and on a missing tests repo before it reads anything); inputRecordLines() -> the record's lines,
// `<path>\t<mtimeMs>\t<size>`, the path relative to the umbrella; compareRecords(recorded, current) -> { changed, added,
// removed } (pure: two lists of record lines); lastBuildTime() -> the stamp's mtime, or undefined; buildStaleness() ->
// { stale: false } or { stale: true, why, changed, added, removed }. A listing that fails throws.

const fs = require('fs');
const path = require('path');
const { compiledFiles } = require('./source-files');

const FIZZYGUM = path.resolve(__dirname, '..', '..');
const UMBRELLA = path.resolve(FIZZYGUM, '..');
const STAMP = path.resolve(UMBRELLA, 'Fizzygum-builds', 'latest', '.build-stamp');   // the build writes it
const RECORD = path.join(FIZZYGUM, '.latest-build-inputs');   // and this, outside the tree (gitignored)
const BUILD_FILES = ['build_it_please.sh', 'buildSystem/run-build.js', 'buildSystem/build.js', 'buildSystem/lib/profile.js',
  'buildSystem/parts.json', 'src/index.html', 'package-lock.json'];
// the files the build reads by name, outside the partition, are named once, by the build (run-build.js READS_BY_NAME:
// a rename there is a rename here), and asked for when the inputs are listed, never when this module loads: every
// runner loads it, and a run-build.js in the middle of an edit then reads as inputs that cannot be listed (which the
// runners' guard reports), not as a crash of every runner at its start
const INPUT_TREES = ['font-assets'];   // every file under them
const PROFILES = 'buildSystem/profiles';   // its *.json (an editor's backup beside them is no input)

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

function buildInputs() {
  const { READS_BY_NAME } = require('../run-build');
  const profiles = path.join(FIZZYGUM, PROFILES);
  const files = [
    ...compiledFiles(),
    ...[...BUILD_FILES, ...Object.values(READS_BY_NAME), ...declaredPayloads()].map((f) => path.join(FIZZYGUM, f)),
    ...fs.readdirSync(profiles).filter((f) => f.endsWith('.json')).map((f) => path.join(profiles, f)),
    ...INPUT_TREES.flatMap((d) => filesUnder(path.join(FIZZYGUM, d))),
  ];
  return [...new Set(files)].filter((file) => fs.existsSync(file)).sort();
}

const relative = (file) => path.relative(UMBRELLA, file);

function inputRecordLines() {
  return buildInputs().map((file) => { const st = fs.statSync(file); return relative(file) + '\t' + st.mtimeMs + '\t' + st.size; });
}

function compareRecords(recorded, current) {
  const entry = (line) => { const tab = line.indexOf('\t'); return [line.slice(0, tab), line.slice(tab + 1)]; };
  const before = new Map(recorded.map(entry)), now = new Map(current.map(entry));
  const changed = [], added = [], removed = [];
  for (const [file, facts] of now) {
    if (!before.has(file)) added.push(file); else if (before.get(file) !== facts) changed.push(file);
  }
  for (const file of before.keys()) if (!now.has(file)) removed.push(file);
  return { changed: changed.sort(), added: added.sort(), removed: removed.sort() };
}

function lastBuildTime() {
  try { return fs.statSync(STAMP).mtimeMs; } catch (_) { return undefined; }
}

function buildStaleness() {
  const stampTime = lastBuildTime();
  if (stampTime === undefined) return { stale: true, why: 'no completed build (no .build-stamp: a build removes it as it starts)', changed: [], added: [], removed: [] };
  let lines;
  try { lines = fs.readFileSync(RECORD, 'utf8').split('\n').filter(Boolean); } catch (_) { lines = undefined; }
  if (!lines || lines[0] !== '# build started at ' + stampTime) {
    return { stale: true, why: 'no record of the inputs the last build read (' + relative(RECORD) + ' is ' +
      (lines ? "another build's" : 'missing') + ')', changed: [], added: [], removed: [] };
  }
  const d = compareRecords(lines.slice(1), inputRecordLines());
  const count = d.changed.length + d.added.length + d.removed.length;
  if (!count) return { stale: false, stampTime };
  return Object.assign({ stale: true, why: count + " of the build's inputs are not the ones the last build read" }, d);
}

if (require.main === module) {
  const marker = process.argv[2] === '--record' && process.argv[3];
  if (!marker) { console.error('build-inputs.js: the one invocation is --record <start marker> (exit 2)'); process.exit(2); }
  process.stdout.write('# build started at ' + fs.statSync(marker).mtimeMs + '\n' + inputRecordLines().join('\n') + '\n');
}

module.exports = { buildInputs, inputRecordLines, compareRecords, lastBuildTime, buildStaleness };

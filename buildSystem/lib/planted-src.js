'use strict';
// planted-src.js — a static gate's bite-proof runs the REAL gate on a COPY of its input tree that carries a plant.
//
// A gate's rule is believed only once a planted violation has been seen to fail it, and a plant made once, by hand,
// proves nothing about the gate as it is today. So a static gate's self-test copies the tree the gate reads (src/ by
// default) to a temp dir, ADDS throwaway files carrying the defects (never an edit of a real holder where an addition
// can reach the rule, so a plant cannot drift with a holder's text), runs the gate on the copy through its rail
// (`--src=DIR`, `--tests-dir=DIR`, …) and holds it to what it must say.
//
// A gate reading the compiled sources reads the tests repo's harness too (lib/source-files.js compiledFiles), so its
// proof plants there as well: `testsRepo: true` gives the tree a second copy, of the tests repo's CODE — its harness,
// each test's two files and its scripts (lib/tests-repo-code.js testsRepoFiles and testNames, lib/what-runs.js
// scriptFiles; no reference images) — and
// every gate run gets `--tests-repo=<that copy>`. A plant, unplant or edit keyed `harness/<rel>` lands in the copy's
// Automator-and-test-harness-src/<rel>; any other key, in the src copy. So a harness plant rides a control that still
// holds the whole real harness (a gate keeping src methods alive through harness callers still passes it).
//
//   proveGate({
//     name: 'check-x',                              // the self-test's verdict name
//     gate: path.join(__dirname, 'check-x.js'),     // spelled with path.join, so lib/what-runs.js sees the launch
//     testsRepo: true,                              // a tests-repo code copy too, plants keyed `harness/<rel>` (above)
//     pass: /\[x\] OK/,                             // the control's pass line
//     control: { plants: { 'BiteProofOk.coffee': text } },            // the sanctioned forms, which must pass
//     runs: [{ label: 'every rule',
//              plants: { 'BiteProofA.coffee': text, … },             // added (or replaced) files
//              unplant: ['boot/x.coffee'],                            // removed files
//              edits: [['WorldWdgt.coffee', /^  _repaint…:/m, '  x:']], // an in-copy edit; must match, else the case fails
//              expect: { A_RULE: /^  BiteProofA\.coffee:3$/m, … },     // each rule id → its OWN violation line
//              absent: [/BiteProofSanctioned/],                       // what the run must not print
//              lines: [/a line it must print that no rule owns/],
//              args: ['--tests-dir=…'] }],                              // this run's extra gate arguments
//     (runs may also be a function of the control's run — { status, out } — for a ratchet sized by the count it prints)
//   });
//
// What the runs must show is lib/prove-rules.js's, shared with the browser rigs' proofs: the CONTROL (the unplanted
// copy plus the sanctioned forms) passes firing no rule; each PLANTED run fails naming exactly the rules it planted,
// each by its own violation line; together they plant EVERY rule the gate can fire.
// `why` on a failed case carries the gate's own failure lines — what names the offender — not its advice footer.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const { parseRulesLine } = require('./gate-rules');
const { proveRules } = require('./prove-rules');

const { SRC, TESTS_REPO, HARNESS_DIR } = require('./source-files');
const BUILD_SYSTEM = path.resolve(__dirname, '..');
const FIZZYGUM = path.dirname(BUILD_SYSTEM);

const PREFIX = 'planted-src-';
const STALE_MS = 60 * 60 * 1000;

function sweepStaleCopies() {
  // a copy whose process was killed (a timeout, a Ctrl-C mid-build) never reaches its exit handler: sweep those
  for (const e of fs.readdirSync(os.tmpdir(), { withFileTypes: true })) {
    if (!e.isDirectory() || !e.name.startsWith(PREFIX)) continue;
    const p = path.join(os.tmpdir(), e.name);
    try { if (Date.now() - fs.statSync(p).mtimeMs > STALE_MS) fs.rmSync(p, { recursive: true, force: true }); } catch (err) { /* a sibling's */ }
  }
}

// The tests repo's CODE at `repo`, copied into `dir` at the same relative paths: what a gate reading that repo reads —
// its harness and each test's two files (lib/tests-repo-code.js), and its scripts as lib/what-runs.js lists them
// (`.js`, `.sh`, `.py`: what runs is read from the shell scripts too).
function copyTestsRepoCode(repo, dir) {
  const { testsRepoFiles, testNames, commandFileOf, metadataFileOf } = require('./tests-repo-code');
  const { scriptFiles } = require('./what-runs');
  const files = testsRepoFiles(repo);
  if (!files) throw new Error(`planted-src: no tests repo at ${repo} to copy`);
  const tests = path.join(repo, 'tests');
  const scripts = scriptFiles({ fizzygum: FIZZYGUM, tests: repo }).filter((f) => f.startsWith(repo + path.sep));
  const code = [...new Set([...files.harness, ...scripts,
    ...testNames(tests).flatMap((n) => [metadataFileOf(tests, n), commandFileOf(tests, n)])])];
  for (const p of code) {
    const q = path.join(dir, path.relative(repo, p));
    fs.mkdirSync(path.dirname(q), { recursive: true });
    fs.copyFileSync(p, q);
  }
}

const HARNESS_KEY = 'harness/';

// A temp tree: a copy of `from` (default src/), or an empty dir (`from: null`), removed at process exit; with
// `testsRepo` (true for this umbrella's, or a tests repo's path) also a copy of that tests repo's code, `tree.testsRepo`.
// Every path a plant, unplant or edit touches is remembered, and reset() puts each back as its original has it, the
// directories a plant made included — so one copy serves a proof's every run.
function plantedTree({ from = SRC, testsRepo = false } = {}) {
  sweepStaleCopies();
  const tempDir = () => {
    const d = fs.mkdtempSync(path.join(os.tmpdir(), PREFIX));
    process.on('exit', () => fs.rmSync(d, { recursive: true, force: true }));
    return d;
  };
  const dir = tempDir();
  if (from) fs.cpSync(from, dir, { recursive: true });
  const repoFrom = testsRepo === true ? TESTS_REPO : testsRepo || undefined;
  // named as the umbrella names the repo, so a reader matching a script by its path's tail (lib/what-runs.js:
  // `../Fizzygum-tests/scripts/x.js` in the build) finds the copy's
  const repoDir = repoFrom && path.join(tempDir(), 'Fizzygum-tests');
  if (repoFrom) copyTestsRepoCode(repoFrom, repoDir);
  // where a key lives: { root, orig, rel } — the copy's root, the tree it copies, the path within both
  const locate = (key) => {
    if (!key.startsWith(HARNESS_KEY)) return { root: dir, orig: from, rel: key };
    if (!repoDir) throw new Error(`planted-src: the plant ${key} is keyed to the harness, and this tree has no tests-repo copy (testsRepo: true)`);
    return { root: path.join(repoDir, HARNESS_DIR), orig: path.join(repoFrom, HARNESS_DIR), rel: key.slice(HARNESS_KEY.length) };
  };
  const touched = new Set();
  const at = (key) => { const { root, rel } = locate(key); touched.add(key); return path.join(root, rel); };
  return {
    dir,
    testsRepo: repoDir,
    plant(key, text) { const p = at(key); fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, text); },
    unplant(key) { fs.rmSync(at(key), { recursive: true, force: true }); },
    // an in-copy edit of a real file: true only when `re` matched (a caller asserts it, so drift fails loudly)
    edit(key, re, replacement) {
      const p = at(key);
      const text = fs.readFileSync(p, 'utf8');
      const next = text.replace(re, replacement);
      if (next === text) return false;
      fs.writeFileSync(p, next);
      return true;
    },
    reset() {
      for (const key of touched) {
        const { root, orig, rel } = locate(key);
        const p = path.join(root, rel);
        fs.rmSync(p, { recursive: true, force: true });
        const original = orig && path.join(orig, rel);
        if (original && fs.existsSync(original)) fs.cpSync(original, p, { recursive: true });
        // a directory a plant made goes with it, so the next run reads the tree its original has, empty directories included
        for (let d = path.dirname(rel); d !== '.'; d = path.dirname(d)) {
          const here = path.join(root, d);
          if ((orig && fs.existsSync(path.join(orig, d))) || !fs.existsSync(here) || fs.readdirSync(here).length) break;
          fs.rmdirSync(here);
        }
      }
      touched.clear();
    },
  };
}

const plantedSrc = () => plantedTree();

// One run of a gate on a tree, from the Fizzygum repo root (where the build runs it). `script` is a path, or a
// buildSystem-relative name.
function runGate(script, treeDir, { rail = '--src=', args = [], cwd = FIZZYGUM } = {}) {
  const file = path.isAbsolute(script) ? script : path.join(BUILD_SYSTEM, script);
  const r = spawnSync(process.execPath, [file, rail + treeDir, ...args], {
    cwd, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024, timeout: 120000,
  });
  const out = `${r.stdout || ''}${r.stderr || ''}`;
  const lines = out.split('\n').filter(Boolean);
  const verdictAt = lines.findIndex((l) => /FAIL|ERROR|RULELESS|operational error|^\s+\S.*\.coffee:\d+/.test(l));
  const shown = verdictAt < 0 ? lines.slice(-4) : lines.slice(verdictAt, verdictAt + 8);
  return { status: r.status, out, rules: parseRulesLine(out, path.basename(file).replace(/\.js$/, '')),
           why: `exit ${r.status}${r.error ? ' error ' + r.error.code : ''}: ${shown.join(' | ')}` };
}

function apply(tree, run) {
  const missed = [];
  for (const [rel, text] of Object.entries(run.plants || {})) tree.plant(rel, text);
  for (const rel of run.unplant || []) tree.unplant(rel);
  for (const [rel, re, replacement] of run.edits || []) if (!tree.edit(rel, re, replacement)) missed.push(`${rel} ${re}`);
  return missed;
}

// `spec.cases`: an existing case set (a self-test that also keeps engine fixtures) — its caller ends it; otherwise
// proveGate opens one under spec.name and prints the verdict itself.
function proveGate(spec) {
  const t = spec.cases || require('./selftest-verdict').cases(spec.name);
  const tree = plantedTree({ from: spec.from === undefined ? SRC : spec.from, testsRepo: spec.testsRepo });
  const opts = { rail: spec.rail || '--src=', args: [...(tree.testsRepo ? ['--tests-repo=' + tree.testsRepo] : []), ...(spec.args || [])],
    cwd: spec.cwd || FIZZYGUM };
  // one gate run on the copy carrying `run`'s plants, the copy reset after it
  const exec = (run) => {
    const missed = apply(tree, run);
    const r = runGate(spec.gate, tree.dir, { ...opts, args: [...opts.args, ...(run.args || [])] });
    tree.reset();
    return { ...r, missed };
  };
  const control = spec.control || {};
  const controlLabel = `the control — the unplanted ${spec.from === null ? 'fixture' : 'copy'}` +
    `${control.plants ? ' plus every sanctioned form' : ''} — passes`;
  const results = { tree, ...proveRules(t, { ...spec, controlLabel }, exec) };
  if (spec.after) spec.after(t, results);
  if (!spec.cases) t.done();
  return results;
}

module.exports = { plantedSrc, plantedTree, runGate, proveGate, SRC, FIZZYGUM };

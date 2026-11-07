'use strict';
// planted-src.js — a static gate's bite-proof runs the REAL gate on a COPY of its input tree that carries a plant.
//
// A gate's rule is believed only once a planted violation has been seen to fail it, and a plant made once, by hand,
// proves nothing about the gate as it is today. So a static gate's self-test copies the tree the gate reads (src/ by
// default) to a temp dir, ADDS throwaway files carrying the defects (never an edit of a real holder where an addition
// can reach the rule, so a plant cannot drift with a holder's text), runs the gate on the copy through its rail
// (`--src=DIR`, `--tests-dir=DIR`, …) and holds it to what it must say.
//
//   proveGate({
//     name: 'check-x',                              // the self-test's verdict name
//     gate: path.join(__dirname, 'check-x.js'),     // spelled with path.join, so lib/what-runs.js sees the launch
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

const SRC = path.resolve(__dirname, '../../src');
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

// A temp tree: a copy of `from` (default src/), or an empty dir (`from: null`), removed at process exit. Every path a
// plant, unplant or edit touches is remembered, and reset() puts each back as `from` has it — so one copy serves a
// proof's every run.
function plantedTree({ from = SRC } = {}) {
  sweepStaleCopies();
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), PREFIX));
  if (from) fs.cpSync(from, dir, { recursive: true });
  process.on('exit', () => fs.rmSync(dir, { recursive: true, force: true }));
  const touched = new Set();
  const at = (rel) => { touched.add(rel); return path.join(dir, rel); };
  return {
    dir,
    plant(rel, text) { const p = at(rel); fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, text); },
    unplant(rel) { fs.rmSync(at(rel), { recursive: true, force: true }); },
    // an in-copy edit of a real file: true only when `re` matched (a caller asserts it, so drift fails loudly)
    edit(rel, re, replacement) {
      const p = at(rel);
      const text = fs.readFileSync(p, 'utf8');
      const next = text.replace(re, replacement);
      if (next === text) return false;
      fs.writeFileSync(p, next);
      return true;
    },
    reset() {
      for (const rel of touched) {
        const p = path.join(dir, rel);
        fs.rmSync(p, { recursive: true, force: true });
        const orig = from && path.join(from, rel);
        if (orig && fs.existsSync(orig)) fs.cpSync(orig, p, { recursive: true });
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
  const tree = plantedTree({ from: spec.from === undefined ? SRC : spec.from });
  const opts = { rail: spec.rail || '--src=', args: spec.args || [], cwd: spec.cwd || FIZZYGUM };
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

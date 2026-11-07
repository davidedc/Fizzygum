'use strict';
// planted-src.js — a static gate's bite-proof runs the REAL gate on a COPY of the real src/ that carries a plant.
//
// A gate's rule is believed only once a planted violation has been seen to fail it, and a plant made once, by hand,
// proves nothing about the gate as it is today. So a static gate's self-test copies src/ to a temp dir, ADDS a
// throwaway class carrying the defect (never an edit of a real holder, so the plant cannot drift with that holder's
// text), runs the gate on the copy through its --src=DIR rail, and requires it to fail naming the plant — and requires
// the unplanted copy, and each exempted variant of the plant, to pass, so a gate that fails on everything cannot pass
// for a bite.
//
//   const tree = plantedSrc();                  // a fresh copy of src/ (removed at process exit)
//   tree.plant('BiteProofX.coffee', text);      // add or replace one file in the copy
//   tree.unplant('BiteProofX.coffee');
//   const r = runGate('check-x.js', tree.dir);  // { status, out, why }: why = the exit + the gate's verdict lines
//
// A control failing is most often the REAL tree carrying a violation (the build runs this before the gate itself), so
// `why` carries the gate's own failure lines — what names the offender — not the advice footer after them.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const SRC = path.resolve(__dirname, '../../src');
const BUILD_SYSTEM = path.resolve(__dirname, '..');

const PREFIX = 'planted-src-';
const STALE_MS = 60 * 60 * 1000;

function plantedSrc() {
  // a copy whose process was killed (a timeout, a Ctrl-C mid-build) never reaches its exit handler: sweep those
  for (const e of fs.readdirSync(os.tmpdir(), { withFileTypes: true })) {
    if (!e.isDirectory() || !e.name.startsWith(PREFIX)) continue;
    const p = path.join(os.tmpdir(), e.name);
    try { if (Date.now() - fs.statSync(p).mtimeMs > STALE_MS) fs.rmSync(p, { recursive: true, force: true }); } catch (err) { /* a sibling's */ }
  }
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), PREFIX));
  fs.cpSync(SRC, dir, { recursive: true });
  process.on('exit', () => fs.rmSync(dir, { recursive: true, force: true }));
  return {
    dir,
    plant(rel, text) { fs.writeFileSync(path.join(dir, rel), text); },
    unplant(rel) { fs.rmSync(path.join(dir, rel), { force: true }); },
  };
}

// One run of a buildSystem gate on a src tree, from the Fizzygum repo root (where the build runs it).
function runGate(script, srcDir) {
  const r = spawnSync(process.execPath, [path.join(BUILD_SYSTEM, script), '--src=' + srcDir], {
    cwd: path.dirname(BUILD_SYSTEM), encoding: 'utf8', maxBuffer: 64 * 1024 * 1024, timeout: 120000,
  });
  const out = `${r.stdout || ''}${r.stderr || ''}`;
  const lines = out.split('\n').filter(Boolean);
  const verdictAt = lines.findIndex((l) => /FAIL|ERROR|operational error|^\s+\S.*\.coffee:\d+/.test(l));
  const shown = verdictAt < 0 ? lines.slice(-4) : lines.slice(verdictAt, verdictAt + 8);
  return { status: r.status, out, why: `exit ${r.status}${r.error ? ' error ' + r.error.code : ''}: ${shown.join(' | ')}` };
}

module.exports = { plantedSrc, runGate };

#!/usr/bin/env node
'use strict';
/*
 * hypothetical-part.js — "what if THESE files were a part?", answered before a file is moved.
 *
 * WHY IT EXISTS. Deciding a partition slice by hand is how you get a slice that cannot exist: the
 * planned shape of the `authoring` extraction ("a toolbar + its buttons + their icons, per toolbar")
 * was falsified only after the analysis, because a toolbar's docked host reaches it through a
 * synchronous hook and those hosts are one inheritance family. This answers the same questions the
 * build gate would, against a grouping that does not exist yet:
 *
 *   - INHERITANCE EDGES from outside — fatal, and not fixable at the call site: you cannot
 *     conditionally extend a class. An inheritance family is INDIVISIBLE, because even a door
 *     naming both parts loads them through Promise.all and orders nothing. Only parts.json
 *     `requires` orders a cross-part load, so an `extends` across parts needs one.
 *   - UNGUARDED REFERENCES from outside — the work list: each is a door that must guard or await.
 *   - CROSS-PART edges — the ones check-part-edges.js scans for once a part is real.
 *
 * ⚠ It shares the gate's classifier (lib/part-edge-scan.js) rather than reimplementing it, so a
 * verdict here means the same thing a verdict there does. Do NOT reintroduce a private copy.
 * ⚠ NEVER answer these questions with a grep: the classifier strips comments and string literals,
 * and prose naming a class has produced false hits in two separate arcs.
 *
 * Usage:  node buildSystem/hypothetical-part.js <file-or-dir>…      (paths relative to Fizzygum/)
 *         fg hypopart src/authoring/DocumentWdgt.coffee src/authoring/SlideWdgt.coffee
 */

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { codePartOf, guardedPartsPerLine } = require('./lib/part-edge-scan');

const REPO = path.resolve(__dirname, '..');
const parts = JSON.parse(fs.readFileSync(path.join(REPO, 'buildSystem/parts.json'), 'utf8')).parts;

const argv = process.argv.slice(2);
if (!argv.length) {
  console.error('usage: hypothetical-part.js <file-or-dir>…   (paths relative to the Fizzygum repo)');
  process.exit(2);
}

const shippable = execFileSync('python3', ['-B', 'buildSystem/build.py', '--list-shippable'],
  { cwd: REPO, encoding: 'utf8' }).split('\n').filter(Boolean);

const dirToPart = new Map();
for (const [n, p] of Object.entries(parts)) {
  if (n.startsWith('//')) continue;
  for (const d of p.dirs || []) dirToPart.set(path.posix.normalize(d), n);
}
const ownerOf = (rel) => dirToPart.get(path.posix.normalize(path.posix.dirname(rel)));
const isLazy = (n) => n !== 'core' && !!parts[n] && parts[n].eager === false;

// ---- the hypothetical membership ------------------------------------------------------------
const member = new Set();
for (const a of argv) {
  const norm = a.replace(/^\.\//, '').replace(/\/$/, '');
  if (norm.endsWith('.coffee')) {
    if (!ownerOf(norm)) { console.error('not a shippable source: ' + norm); process.exit(2); }
    member.add(norm);
  } else {
    let hit = 0;
    for (const r of shippable) if (path.posix.dirname(r) === norm) { member.add(r); hit++; }
    if (!hit) { console.error('no shippable sources under: ' + norm); process.exit(2); }
  }
}

const HYPO = '(the hypothetical part)';
const ownerOfClass = new Map();
for (const rel of member) ownerOfClass.set(path.basename(rel, '.coffee'), HYPO);

const patterns = [...ownerOfClass.keys()].sort((a, b) => b.length - a.length).map(n => ({
  name: n,
  ref: new RegExp('\\b' + n + '\\b'),
  inherit: new RegExp('(?:\\bextends\\s+' + n + '\\b)|(?:@augmentWith\\s+' + n + '\\b)')
}));

// ---- scan everything that STAYS BEHIND --------------------------------------------------------
const refs = [], inherits = [], guarded = [];
for (const rel of shippable) {
  const owner = ownerOf(rel);
  if (!owner || member.has(rel)) continue;
  const lines = fs.readFileSync(path.join(REPO, rel), 'utf8').split('\n');
  const scopes = guardedPartsPerLine(lines, ownerOfClass, { [HYPO]: {} });
  for (let i = 0; i < lines.length; i++) {
    const code = codePartOf(lines[i]);
    if (!code.trim()) continue;
    for (const p of patterns) {
      if (!p.ref.test(code)) continue;
      const rec = { rel, owner, line: i + 1, name: p.name, text: lines[i].trim() };
      if (p.inherit.test(code)) inherits.push(rec);
      else if (scopes[i].has(HYPO)) guarded.push(rec);
      else refs.push(rec);
    }
  }
}

// ---- report -----------------------------------------------------------------------------------
const codeBytes = (rel) => fs.readFileSync(path.join(REPO, rel), 'utf8').split('\n')
  .reduce((a, l) => { const c = l.split('#')[0].replace(/\s+$/, ''); return c.trim() ? a + c.length + 1 : a; }, 0);
const src = [...member].reduce((a, r) => a + fs.statSync(path.join(REPO, r)).size, 0);
const cod = [...member].reduce((a, r) => a + codeBytes(r), 0);

console.log(`HYPOTHETICAL PART: ${member.size} file(s), ${(src / 1024).toFixed(1)} KB source, ` +
            `${(cod / 1024).toFixed(1)} KB code (${Math.round(100 * cod / src)}% code)`);
console.log(`  ⚠ estimate a slice's payoff from CODE bytes, and even then treat it as a guess: the`);
console.log(`    image tracks CLASS COUNT as much as bytes (54 classes took 1.65× what 4 did, at`);
console.log(`    the same source size). Fingerprint two builds — see \`fg fingerprint\`.`);
console.log(`==> ${refs.length} unguarded reference(s), ${inherits.length} inheritance edge(s), ` +
            `${guarded.length} already guarded/awaited`);

const group = (rows) => {
  const by = new Map();
  for (const r of rows) {
    const k = `${r.owner}  ${r.rel}`;
    if (!by.has(k)) by.set(k, []);
    by.get(k).push(r);
  }
  return [...by.entries()].sort((a, b) => b[1].length - a[1].length);
};

if (inherits.length) {
  console.log('\n-- ⛔ INHERITANCE EDGES — the partition is wrong, or these files must come too --');
  console.log('   An inheritance family is INDIVISIBLE unless the deriving part declares a');
  console.log('   parts.json `requires` on the base\'s part: only that orders a cross-part load.');
  for (const [k, rows] of group(inherits))
    for (const r of rows) console.log(`  ${k}:${r.line}  ${r.name}\n      ${r.text.slice(0, 110)}`);
}

if (refs.length) {
  console.log('\n-- UNGUARDED REFERENCES — the work list, by the file that stays behind --');
  for (const [k, rows] of group(refs)) {
    const lazyNote = isLazy(rows[0].owner) ? '' : '  [present at boot: must guard or await]';
    console.log(`  ${k}  (${rows.length})${lazyNote}`);
    for (const r of rows.slice(0, 6)) console.log(`      :${r.line}  ${r.name}   ${r.text.slice(0, 100)}`);
    if (rows.length > 6) console.log(`      … +${rows.length - 6} more`);
  }
}

const fromParts = [...new Set(refs.concat(inherits).map(r => r.owner))].filter(o => o !== 'core');
if (fromParts.length) {
  console.log('\n-- ⚠ CROSS-PART callers: ' + fromParts.join(', '));
  console.log('   Each needs the new part named at its door, or in its parts.json `requires`.');
}

if (guarded.length) {
  console.log('\n-- already guarded or awaited (no work) --');
  for (const [k, rows] of group(guarded)) console.log(`  ${k}  (${rows.length})`);
}

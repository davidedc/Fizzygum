#!/usr/bin/env node
'use strict';
/*
 * census-doc-member-refs.js — ADVISORY census (not a build gate): does an INSTRUCTION doc name a
 * class member that no longer resolves?
 *
 * WHY THIS EXISTS. The instruction-drift audit (2026-08-21) asks a different question from the
 * veracity audit: not "is this statement still true?" but "does this tell someone to do something
 * we no longer do?" -- because a false statement misleads a reader once, while a false INSTRUCTION
 * manufactures new violations for as long as people follow it. The `/author-macro-test` skill's
 * `eval` row produced 28 call sites before anyone noticed.
 *   That audit's mechanical detectors mostly came back empty -- the docs' FILE and command
 * references are clean, which the docs-audit skill already covers. This one did not: it found the
 * skill telling authors that the inspector's save goes to `@target.injectProperty` when
 * InspectorWdgt has no `@target` at all (and its class comment says so deliberately, because
 * `@target` elsewhere means a dataflow consumer or a dispatch receiver), plus two members in
 * src/macros/CLAUDE.md that had drifted from code sitting a few files away.
 *
 * WHAT IT DOES. Indexes every class in BOTH repos' CoffeeScript (name, members, `extends` parent),
 * then reads every CLAUDE.md and .claude/skills/*.md and checks each backticked `Class.member`
 * reference against the real chain. Resolution follows three paths a naive scan gets wrong:
 *   - INHERITANCE: walks the `extends` chain, so a base's member is not a false positive.
 *   - TESTSUPPORT INSTALLS: `*TestSupport` classes declare members and copy them onto a core class
 *     at boot; the mapping is read from globalFunctions.coffee's `installOnto` calls rather than
 *     guessed from the name (WorldTestSupport -> WorldWdgt, but MenusHelperTestSupport ->
 *     MenusHelper, so the name alone does not tell you).
 *   - META-EMITTED STATICS: src/meta/Class.coffee emits `window.<Name>.instances = new Set` for
 *     every class at definition time, so `Widget.instances` is real and invisible to any source scan.
 *
 * ⚠ ADVISORY ON PURPOSE, and it must stay that way. A doc naming a retired member in a TOMBSTONE
 * ("⛔ X is RETIRED, do not reintroduce it") is doing exactly the right thing -- that is the
 * OPPOSITE of drift, and it is most of what is left after the real hits are fixed. Gating this
 * would need an allowlist of tombstones, which would rot faster than the docs it guards. So it
 * separates likely-tombstone lines from the rest and asks a human to read the remainder.
 *
 * Exit 0 always (advisory). Run from anywhere: node buildSystem/census-doc-member-refs.js
 * Flags: --all (do not hide the likely-tombstone bucket)
 */
const fs = require('fs');
const path = require('path');

const FZ = path.resolve(__dirname, '..');
const ROOT = path.resolve(FZ, '..');
const SHOW_ALL = process.argv.includes('--all');

// ---- index every class: members + extends parent ---------------------------------------------
const classes = new Map();
function scanDir(dir) {
  let entries;
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch (e) { return; }
  for (const e of entries) {
    if (e.name === 'node_modules' || e.name === '.git') continue;
    const p = path.join(dir, e.name);
    if (e.isDirectory()) { scanDir(p); continue; }
    if (!e.name.endsWith('.coffee')) continue;
    let current;
    for (const line of fs.readFileSync(p, 'utf8').split('\n')) {
      const cm = /^class\s+([A-Za-z_][A-Za-z0-9_]*)(?:\s+extends\s+([A-Za-z_][A-Za-z0-9_]*))?/.exec(line);
      if (cm) { current = cm[1]; classes.set(current, { members: new Set(), parent: cm[2] }); continue; }
      if (!current) continue;
      const mm = /^  @?([A-Za-z_][A-Za-z0-9_]*)\s*:/.exec(line);
      if (mm) classes.get(current).members.add(mm[1]);
    }
  }
}
scanDir(path.join(FZ, 'src'));
scanDir(path.join(ROOT, 'Fizzygum-tests', 'Automator-and-test-harness-src'));

// ---- the *TestSupport -> core class map, READ from the boot path (never guessed) --------------
const installs = new Map();
const bootPath = path.join(FZ, 'src', 'boot', 'globalFunctions.coffee');
if (fs.existsSync(bootPath)) {
  for (const m of fs.readFileSync(bootPath, 'utf8')
    .matchAll(/([A-Za-z_][A-Za-z0-9_]*TestSupport)\.installOnto\s+([A-Za-z_][A-Za-z0-9_]*)/g)) {
    installs.set(m[2], m[1]);
  }
}

// ---- statics the meta-system emits onto EVERY class at definition time ------------------------
// src/meta/Class.coffee: `window.<Name>.instances = new Set;`
const META_EMITTED = new Set(['instances']);

function answers(cls, member, depth = 0) {
  if (META_EMITTED.has(member)) return true;
  const c = classes.get(cls);
  if (!c || depth > 20) return false;
  if (c.members.has(member)) return true;
  const support = installs.get(cls);
  if (support && classes.has(support) && classes.get(support).members.has(member)) return true;
  return c.parent ? answers(c.parent, member, depth + 1) : false;
}

// ---- the instruction docs ---------------------------------------------------------------------
const docs = [];
(function findDocs(dir, depth) {
  if (depth > 6) return;
  let entries;
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch (e) { return; }
  for (const e of entries) {
    if (e.name === 'node_modules' || e.name === '.git' || e.name === 'latest') continue;
    const p = path.join(dir, e.name);
    if (e.isDirectory()) { findDocs(p, depth + 1); continue; }
    if (e.name === 'CLAUDE.md' || (e.name.endsWith('.md') && p.includes(path.join('.claude', 'skills')))) docs.push(p);
  }
})(ROOT, 0);

// A line that says the thing is GONE is a tombstone, not an instruction to use it. ⚠ Checked over a
// small WINDOW, not the single line: a tombstone routinely spans a sentence, and the member being
// buried often sits a line or two after the word that buries it ("Gone: `A`,\n `B`, the `C`...").
// Measured — a per-line test reported both of src/dataflow/CLAUDE.md's already-buried members.
const TOMBSTONE = /\b(retired|RETIRED|gone|Gone|deleted|removed|no longer|used to|gets? mangled)\b|⛔/;
const TOMBSTONE_LOOKBACK = 2;

// language/file suffixes that look like members but are not
const NOT_A_MEMBER = /^(coffee|js|py|sh|md|json|html|png|prototype|call|apply|bind|name|length)$/;

const live = [];
const tombstones = [];
for (const doc of docs.sort()) {
  const rel = path.relative(ROOT, doc);
  const lines = fs.readFileSync(doc, 'utf8').split('\n');
  const buriedNear = (i) => lines.slice(Math.max(0, i - TOMBSTONE_LOOKBACK), i + 1).some((l) => TOMBSTONE.test(l));
  lines.forEach((line, i) => {
    for (const code of (line.match(/`[^`]+`/g) || [])) {
      for (const m of code.matchAll(/\b([A-Z][A-Za-z0-9_]*)\.([a-z_][A-Za-z0-9_]*)\b/g)) {
        const [, cls, member] = m;
        if (NOT_A_MEMBER.test(member)) continue;
        if (!classes.has(cls)) continue;          // not one of ours
        if (answers(cls, member)) continue;
        (buriedNear(i) ? tombstones : live).push({ at: `${rel}:${i + 1}`, ref: `${cls}.${member}`, line: line.trim() });
      }
    }
  });
}

const report = (title, list) => {
  console.log(`\n== ${title}: ${list.length} ==`);
  for (const h of list) {
    console.log(`  ${h.ref}   ${h.at}`);
    console.log(`     ${h.line.slice(0, 150)}`);
  }
};

console.log(`[doc-member-refs] ${classes.size} classes indexed · ${docs.length} instruction docs · ` +
            `${installs.size} TestSupport install(s) read from the boot path`);
report('REFERENCES THAT DO NOT RESOLVE — read each one', live);
if (SHOW_ALL) report('named in a likely TOMBSTONE (correct — the doc says it is gone)', tombstones);
else console.log(`\n(${tombstones.length} more sit on lines that read as tombstones — correct usage. --all to list them.)`);
console.log('\nAdvisory: a hit is a CANDIDATE. Docs legitimately name members of classes they do not\n' +
            'own, and name retired ones in tombstones. Exit 0 always.');

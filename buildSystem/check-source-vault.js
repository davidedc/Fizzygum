#!/usr/bin/env node
'use strict';
// check-source-vault.js — build gate TOMBSTONING the retired `window.<Name>_coffeSource` source
// delivery. Mirrors the check-region-markers.js idiom: a hard rule, stated as a baseline of zero.
//
// WHAT WAS RETIRED (arc 4 Phase 0, docs/archive/build-arc-4-dynamic-parts-plan.md §5.1).
// Fizzygum ships its ~500 classes as TEXT and compiles them in the browser. Until arc 4, build.py
// emitted each one as its own window global — `window.Widget_coffeSource = "…"` — and the only way
// to ask "which sources do we have?" was `Object.keys(window).filter(k => k.endsWith(...))`. Three
// boot-side readers did that. It worked while the answer was always "all of them", but it cannot
// express the question a part system asks: WHICH sources belong to WHICH slice, so that a slice can
// be loaded on demand. So the globals were replaced by ONE registry, src/boot/source-vault.coffee:
// `SourceVault.store(name, text, part)` / `.get(name)` / `.names()` / `.namesForPart(part)`.
//
// WHY A GATE AND NOT JUST A DELETION. The completion doctrine (§0.2): a retirement that is not
// gated grows back. This is the cheap tombstone. Both patterns below are FORBIDDEN OUTRIGHT — there
// is no baseline to tighten, because the conversion completed inside the phase that started it.
//
// WHAT IT FORBIDS, in src/**/*.coffee:
//   1. the `_coffeSource` identifier, ANYWHERE (a global read, a global write, or a built-up
//      "<name>_coffeSource" string). The naming convention WAS the registry, so banning the
//      identifier bans the mechanism. Read a source with `SourceVault.get name` instead.
//   2. `Object.keys(window)` inside src/boot/** — the boot layer is where source DISCOVERY lives,
//      and there is now exactly one way to discover sources there: `SourceVault.names()` (or
//      `SourceVault.namesForPart part`). The boot layer does not learn what exists by scanning the
//      global object.
// Comments are NOT exempt: a comment naming the dead mechanism as if it were live is exactly the
// stale-documentation failure this repo's comment rubric targets. Say "the SourceVault" instead.
//
// DELIBERATELY OUT OF SCOPE — two `Object.keys(window)` scans OUTSIDE the boot layer that this gate
// does NOT flag, so a later reader knows they were considered rather than missed:
// src/WorldWdgt.coffee's widget-class list and src/serialization/Serializer.coffee's `*Wdgt`/`*Widget`
// sweep. Both enumerate CLASSES (for a creation menu / for serialization), not SOURCES; they predate
// this arc, have nothing to do with source delivery, and narrowing rule 2 to src/boot is what keeps
// this gate about the mechanism it retired instead of quietly starting a different campaign.
//
// ONE EXEMPT FILE: src/boot/source-vault.coffee itself, whose header has to be able to name the
// mechanism it replaced — a tombstone that cannot say what it buries is not a tombstone.
//
// Scope: src/**/*.coffee only (the build's own python/shell side is not text-wrapped source).
// Runs for every build flavour — the rule is a property of the source, not of what is being built.

const fs = require('fs');
const path = require('path');

const SRC = path.resolve(__dirname, '../src');
const REPO = path.resolve(__dirname, '..');

// the tombstone itself — see the header
const EXEMPT = ['src/boot/source-vault.coffee'];

const RULES = [
  {
    id: 'coffeSource-global',
    // matches window.Foo_coffeSource, window[x + "_coffeSource"], bare Foo_coffeSource, ...
    re: /_coffeSource/,
    // every .coffee under src/
    appliesTo: () => true,
    baseline: 0,
    why: 'The per-class `window.<Name>_coffeSource` globals are RETIRED (arc 4).',
    instead: 'Read a source with `SourceVault.get name` (src/boot/source-vault.coffee).'
  },
  {
    id: 'boot-window-key-scan',
    re: /Object\.keys\s*\(\s*window\s*\)/,
    // BOOT LAYER ONLY: the two class-enumerating scans outside it are a different thing (header)
    appliesTo: (rel) => rel.startsWith('src/boot/'),
    baseline: 0,
    why: 'Discovering sources by scanning `Object.keys(window)` is RETIRED (arc 4): the window is not a registry.',
    instead: 'Enumerate with `SourceVault.names()`, or `SourceVault.namesForPart part` for one part.'
  }
];

function walk(dir, out) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(p, out);
    else if (entry.isFile() && entry.name.endsWith('.coffee')) out.push(p);
  }
  return out;
}

const hits = Object.create(null);
for (const rule of RULES) hits[rule.id] = [];

for (const file of walk(SRC, [])) {
  const rel = path.relative(REPO, file);
  if (EXEMPT.includes(rel)) continue;
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  for (let i = 0; i < lines.length; i++) {
    for (const rule of RULES) {
      if (rule.appliesTo(rel) && rule.re.test(lines[i])) {
        hits[rule.id].push(`${rel}:${i + 1}: ${lines[i].trim()}`);
      }
    }
  }
}

const total = RULES.reduce((n, r) => n + hits[r.id].length, 0);
console.log(`[source-vault] scan done — ${total} occurrence(s): ` +
  RULES.map(r => `${r.id}=${hits[r.id].length}/${r.baseline}`).join(' '));

let failed = false;
for (const rule of RULES) {
  const found = hits[rule.id];
  if (found.length > rule.baseline) {
    console.error(`\n[source-vault] FAIL -- '${rule.id}': ${found.length} > baseline ${rule.baseline}.`);
    console.error(`  ${rule.why}`);
    console.error(`  ${rule.instead}`);
    for (const h of found) console.error(`    ${h}`);
    failed = true;
  }
}

if (failed) process.exit(1);
console.log('[source-vault] OK -- the retired source-delivery patterns stay dead.');
process.exit(0);

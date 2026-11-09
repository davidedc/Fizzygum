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
// WHAT IT FORBIDS, in the compiled sources:
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
// DELIBERATELY OUT OF SCOPE — enumerating CLASSES, which is not source delivery: boot's
// `allClassFunctions()` (src/boot/globalFunctions.coffee) walks `Object.getOwnPropertyNames window` for the class
// marker, and the creation menu and the Serializer ask it. Rule 2 matches `Object.keys` of the window ITSELF (with or
// without parentheses), never of a table hung on it (`Object.keys(window.FIZZYGUM_PARTS)`), and only in src/boot:
// keeping it about the mechanism it retired is what stops it quietly starting a different campaign.
//
// ONE EXEMPT FILE: src/boot/source-vault.coffee itself, whose header has to be able to name the
// mechanism it replaced — a tombstone that cannot say what it buries is not a tombstone. An exempt
// path that is no src file, or whose text holds no hit the exemption excuses, FAILS as stale
// (STALE_ALLOWLIST_ENTRY): it would only hide the retired pattern if it ever came back there.
//
// Scope: the compiled sources (lib/source-files.js compiledFiles: src/ and the tests repo's harness; the build's own
// python/shell side is not text-wrapped source). Runs for every build flavour — the rule is a property of the source,
// not of what is being built.
//
// Run from the Fizzygum/ repo root (build_it_please.sh does): node ./buildSystem/check-source-vault.js [--src=DIR]
// [--tests-repo=DIR] — the rails check another src tree or tests repo (a copy carrying a plant); paths are keyed
// `src/…` from whichever src tree it reads (`harness/…` for a harness file), so the exemption and rule 2's scope hold
// on a copy too. That both rules and both stale-exemption rules BITE is proven on every build by
// check-source-vault-selftest.js.

const fs = require('fs');
const { rejectUnknownArgs, rejectPositionalArgs } = require('./lib/cli-args');
const { compiledFiles, sourceRoots, sourceName, SOURCE_RAILS } = require('./lib/source-files');
const gateRules = require('./lib/gate-rules').forGate(__filename);

const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, [...SOURCE_RAILS], 'source-vault');
rejectPositionalArgs(ARGV, 'source-vault', 'a src tree is named with --src=DIR');
const ROOTS = sourceRoots(ARGV, 'source-vault');

// the tombstone itself — see the header
const EXEMPT = ['src/boot/source-vault.coffee'];

const RULES = [
  {
    id: 'coffeSource-global',
    // matches window.Foo_coffeSource, window[x + "_coffeSource"], bare Foo_coffeSource, ...
    re: /_coffeSource/,
    // every compiled source
    appliesTo: () => true,
    baseline: 0,
    why: 'The per-class `window.<Name>_coffeSource` globals are RETIRED (arc 4).',
    instead: 'Read a source with `SourceVault.get name` (src/boot/source-vault.coffee).'
  },
  {
    id: 'boot-window-key-scan',
    re: /Object\.keys\s*(?:\(\s*window\s*\)|\s+window\b(?!\s*[.\[(]))/,
    // BOOT LAYER ONLY: the two class-enumerating scans outside it are a different thing (header)
    appliesTo: (rel) => rel.startsWith('src/boot/'),
    baseline: 0,
    why: 'Discovering sources by scanning `Object.keys(window)` is RETIRED (arc 4): the window is not a registry.',
    instead: 'Enumerate with `SourceVault.names()`, or `SourceVault.namesForPart part` for one part.'
  }
];
gateRules.declare(RULES.map((r) => r.id));

const hits = Object.create(null);
for (const rule of RULES) hits[rule.id] = [];

const exemptHits = Object.create(null);   // exempt path -> how many hits its exemption excused
for (const file of compiledFiles(ROOTS)) {
  const rel = sourceName(file, ROOTS, 'src/');
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  if (EXEMPT.includes(rel)) {
    exemptHits[rel] = lines.filter((l) => RULES.some((rule) => rule.appliesTo(rel) && rule.re.test(l))).length;
    continue;
  }
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
    for (const h of found) console.error(gateRules.fired(rule.id, `    ${h}`));
    failed = true;
  }
}

for (const rel of EXEMPT) {
  if (!(rel in exemptHits)) console.error(gateRules.fired('STALE_EXEMPT_MISSING', `\n[source-vault] FAIL -- STALE_ALLOWLIST_ENTRY EXEMPT '${rel}': no such src file, so the exemption names something that moved: fix the path or delete the entry.`));
  else if (exemptHits[rel] === 0) console.error(gateRules.fired('STALE_EXEMPT_UNUSED', `\n[source-vault] FAIL -- STALE_ALLOWLIST_ENTRY EXEMPT '${rel}': the file holds no hit of either rule, so the exemption excuses nothing: delete the entry.`));
  else continue;
  failed = true;
}

if (failed) process.exit(1);
console.log('[source-vault] OK -- the retired source-delivery patterns stay dead.');
process.exit(0);

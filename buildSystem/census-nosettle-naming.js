#!/usr/bin/env node
'use strict';
/*
 * census-nosettle-naming.js — ADVISORY census (not a build gate): the Topic-3 question of
 * docs/archive/settle-tier-followups-examination-plan.md — "does every non-settling private
 * fn carry *NoSettle?" — answered as the two checkable claims that question decomposes into
 * (the plan's own refinement: a blanket rename is NOT the doctrine — the non-settling private
 * surface is several NAMED families, and only a *core of a settling wrapper* must carry the
 * suffix so check-thin-wraps + layering rule [G] can pair it):
 *
 *   A) LYING SUFFIX — a *NoSettle-named def whose body reaches a settle tier
 *      (_settleLayoutsAfter or the join lane). Must be 0: the suffix claims "no settle".
 *   B) MIS-NAMED CORE — a settling wrapper whose SETTLE CLOSURE delegates the mutation to a
 *      private method that is neither a *NoSettle core nor a member of a recognized
 *      non-settling family. This is the escape no gate asserts: check-thin-wraps starts FROM
 *      a `_<name>NoSettle` def and constrains its twin, so a wrapper whose core never took
 *      the suffix is invisible to it; layering [L] only bans the suffix on callbacks.
 *
 * Recognized non-settling families (the FAMILIES table below, per the Topic-3 inventory):
 *   *NoSettle cores · the settle tiers themselves · the private repaint verbs · notification
 *   callbacks (_reactTo* and _before*, settle-neutral by rule [J]) · the immediate geometry
 *   mutators (the apply-2x2 corners, their _apply*Base twins, _commitBounds, and the convenience
 *   movers/setters) · __ leaves (incl. __commit* and __markForRelayout) · the layout machinery
 *   (_reLayout*, _positionAndResizeChildren, _invalidateLayout, _reFitContainer*,
 *   _reFitMyTrackingContainer*) · _*Connector entrypoints (the [P] join lane) · *DeferredSettle
 *   twins ([O]). Everything else is a plain _ helper/query, which has its OWN correct name —
 *   the plan's stated reason this is a census, not a sweep.
 *
 * WHERE THE NAMES COME FROM. The settle tiers are READ from Widget by lib/settle-tiers.js, the
 * repaint verbs by lib/repaint-verbs.js, and the immediate geometry mutators are the named groups of
 * lib/immediate-mutators.js, which holds them to the compiled sources both ways (every entry names a method
 * defined there; every Widget-own `_apply*`/`_commit*` method is claimed by a group or listed in its NOT_CORNERS);
 * each library throws when its names are stale. The rest of FAMILIES is a stated table held to the compiled
 * sources here: every entry must match a method defined there. An entry that matches nothing is a family that
 * moved, and the methods it should recognise would fall to 'plain' with nothing said.
 *
 * Parsing machinery: every source is read through lib/coffee-mask.js (each line's bare code: comments
 * and literal contents blanked); the method grouping is the shared
 * lib/coffee-method-header.js methodBoundary (2-space class methods, mixin onceAddedClassProperties
 * members).
 *
 * It reads the compiled sources (lib/source-files.js compiledFiles: src/ and the tests repo's harness).
 *
 * Exit 0 whatever buckets A/B hold (advisory). Exit 2, before any census is printed, when the
 * census's own names are stale: a library throw, or a stated FAMILIES entry that names nothing.
 * Run from anywhere: node buildSystem/census-nosettle-naming.js [--src=DIR] [--tests-repo=DIR] (the rails read
 * another src tree / tests repo)
 */

const fs = require('fs');
const path = require('path');
const { rejectUnknownArgs, rejectPositionalArgs } = require('./lib/cli-args');
const { compiledFiles, sourceRoots, sourceName, SOURCE_RAILS } = require('./lib/source-files');

const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, [...SOURCE_RAILS], 'census-nosettle-naming');
rejectPositionalArgs(ARGV, 'census-nosettle-naming', 'a src tree is named with --src=DIR');
const ROOTS = sourceRoots(ARGV, 'census-nosettle-naming');
const SRC = ROOTS.src;
const { methodBoundary } = require('./lib/coffee-method-header');

let SETTLE_TIERS, REPAINT_VERBS, IMMEDIATE_MUTATORS;
try {
  SETTLE_TIERS = require('./lib/settle-tiers').settleTiers(SRC).all;
  REPAINT_VERBS = require('./lib/repaint-verbs').repaintVerbs(SRC);
  // the immediate geometry mutators: they mutate geometry in place and never settle, so they carry no suffix —
  // every group of the module (the polymorphic apply corners, their arrange-bypass *Base twins, the silent
  // commit corner, the convenience movers / setters / resizer)
  IMMEDIATE_MUTATORS = require('./lib/immediate-mutators').immediateMutators(ROOTS).all;
} catch (e) { console.error('census-nosettle-naming: operational error:', e.message); process.exit(2); }
const SETTLE_CALL = new RegExp('[@.]\\s*(' + SETTLE_TIERS.join('|') + ')\\b');   // any tier: the single one or the join lane

// The recognized non-settling families (names that legitimately lack the NoSettle suffix), in the order
// familyOf tries them. An entry is an exact NAME (a string) or a name PATTERN (a RegExp). A row tagged 'read'
// takes its names from a library, which holds them to src itself; the other rows are stated here.
const FAMILIES = [
  ['nosettle-core',     [/NoSettle$/]],
  ['settle-tier',       SETTLE_TIERS, 'read'],
  ['invalidation',      REPAINT_VERBS, 'read'],                 // the PRIVATE repaint verbs (invalidation-privacy standing rule) — settle-neutral by design
  ['callback',          [/^_reactTo[A-Z]/, /^_before[A-Z]/]],   // rule [J]/[L]
  ['immediate-mutator', IMMEDIATE_MUTATORS, 'read'],
  ['leaf',              [/^__/]],                               // the [I] leaves, incl. __commit* and __markForRelayout
  ['layout-machinery',  [/^_reLayout/, /^_positionAndResizeChildren/, '_invalidateLayout', /^_reFitContainer/, /^_reFitMyTrackingContainer/]],
  ['connector',         [/^_\w+Connector$/]],                   // rule [P]
  ['deferred-settle',   [/DeferredSettle$/]],                   // rule [O]
];
const entryMatches = (entry, name) => (typeof entry === 'string' ? entry === name : entry.test(name));

function familyOf(name) {
  for (const [fam, entries] of FAMILIES) {
    if (entries.some((e) => entryMatches(e, name))) return fam;
  }
  return 'plain';                                                         // ordinary _ helper/query
}

const { coffeeMask } = require('./lib/coffee-mask');

// Pass 1: every method def, with its body lines (code-stripped, with raw indent kept).
const defs = [];   // { klass, method, rel, line, body: [{n, code, indent}], settles }
for (const file of compiledFiles(ROOTS)) {
  const rel = sourceName(file, ROOTS, 'src/');
  const klass = path.basename(file, '.coffee');
  const text = fs.readFileSync(file, 'utf8');
  const lines = text.split('\n');
  const masked = coffeeMask(text, rel);
  let cur = null, mixinHashIndent = null;
  const flush = () => { if (cur) defs.push(cur); cur = null; };
  for (let n = 0; n < lines.length; n++) {
    const raw = lines[n];
    const code = masked[n].bare;
    if (!masked[n].continuesLiteral) {             // a line inside a heredoc holds no boundary
      const b = methodBoundary(raw, mixinHashIndent);
      if (b) {
        flush();
        mixinHashIndent = b.mixinHashIndent;
        // the settle tiers name INSTANCE methods; a class-side `@name` method ends the one above it and is
        // not a def of this census
        if (b.kind === 'header' && !b.static) {
          cur = { klass, method: b.method, rel, line: n + 1, body: [], settles: false };
          continue;
        }
      }
    }
    if (cur && code.trim()) {
      const indent = raw.match(/^\s*/)[0].length;
      cur.body.push({ n: n + 1, code, indent });
      if (SETTLE_CALL.test(code)) cur.settles = true;
    }
  }
  flush();
}

// The stated families held to the compiled sources (see the header): an entry naming nothing stops the census before it
// prints a picture keyed on stale names. (The library-read families were held where they are read, above.)
const definedNames = new Set(defs.map(d => d.method));
const staleness = [];
for (const [fam, entries, source] of FAMILIES) {
  if (source === 'read') continue;
  for (const e of entries) {
    if (![...definedNames].some(n => entryMatches(e, n))) staleness.push(`STALE_ALLOWLIST_ENTRY FAMILIES ${fam}: ${e} matches no method defined in the compiled sources`);
  }
}
if (staleness.length) {
  console.error(`census-nosettle-naming: operational error: ${staleness.length} stale name(s) in the census's own tables (buildSystem/census-nosettle-naming.js):`);
  for (const s of staleness) console.error('  ' + s);
  process.exit(2);
}

// Bucket A: *NoSettle-named defs that settle (the suffix lies).
const lying = defs.filter(d => /NoSettle$/.test(d.method) && d.settles);

// Bucket B: settling wrappers whose SETTLE CLOSURE calls a private non-family method.
// The closure = calls on the settle line AFTER the settle token, plus deeper-indented
// continuation lines until dedent (the `=>` body). DIRECT calls only, by doctrine (the [G]
// transitive-closure rejection: name-based reachability balloons and cannot model the guards).
// A private CALL, not a field read: the name must be applied — `(`-called, or CoffeeScript
// paren-less-called (followed by a space and an argument token). A bare `@_editing` in a
// condition (field read, no application) does not match either arm.
const PRIVATE_CALL = /[@.]\s*(_\w+)(?:\s*\(|[ \t]+(?!(?:then|and|or|is|isnt|not|if|unless|in|of)\b)(?=[@_$"'\[{A-Za-z0-9-]))/g;
const misNamedCores = [];   // { wrapper: def, callee, n }
for (const d of defs) {
  if (!d.settles) continue;
  if (SETTLE_TIERS.includes(d.method)) continue;        // the tiers themselves are the flush
  for (let i = 0; i < d.body.length; i++) {
    const bl = d.body[i];
    // calls on the settle line itself, past the settle token
    const tok = bl.code.match(SETTLE_CALL);
    if (!tok) continue;
    const after = bl.code.slice(tok.index + tok[0].length);
    const closureLines = [{ n: bl.n, code: after }];
    for (let j = i + 1; j < d.body.length && d.body[j].indent > bl.indent; j++) {
      closureLines.push({ n: d.body[j].n, code: d.body[j].code });
    }
    for (const cl of closureLines) {
      let m;
      PRIVATE_CALL.lastIndex = 0;
      while ((m = PRIVATE_CALL.exec(cl.code)) !== null) {
        const callee = m[1];
        const fam = familyOf(callee);
        if (fam !== 'plain') continue;                  // NoSettle core / recognized family — fine
        // a callee that is ITSELF a settling wrapper somewhere is a [G] matter, not a naming one
        if (defs.some(o => o.method === callee && o.settles)) continue;
        misNamedCores.push({ wrapper: d, callee, n: cl.n });
      }
    }
  }
}

// The context cross-tab: the whole _-prefixed surface by family × settles.
const privDefs = defs.filter(d => /^_/.test(d.method) || /NoSettle$/.test(d.method));
const tab = new Map();
for (const d of privDefs) {
  const fam = familyOf(d.method);
  const row = tab.get(fam) || { settling: 0, non: 0 };
  if (d.settles) row.settling++; else row.non++;
  tab.set(fam, row);
}

console.log('census-nosettle-naming — Topic 3 (settle-tier-followups): non-settling private fns vs the *NoSettle suffix');
console.log(`  method defs scanned: ${defs.length} (${privDefs.length} private/_-prefixed or NoSettle-suffixed)`);
console.log(`  settle tiers (read from Widget): ${SETTLE_TIERS.join(', ')}`);
console.log(`  repaint verbs (read from Widget): ${REPAINT_VERBS.join(', ')}`);
console.log('\n  the _-prefixed surface, family × settles:');
for (const [fam, row] of [...tab.entries()].sort((a, b) => (b[1].settling + b[1].non) - (a[1].settling + a[1].non))) {
  console.log(`    ${fam.padEnd(18)} settling=${String(row.settling).padStart(3)}  non-settling=${String(row.non).padStart(4)}`);
}
console.log(`\n  A) LYING SUFFIX (*NoSettle def that settles) — must be 0: ${lying.length}`);
for (const d of lying) console.log(`     ${d.klass}.${d.method}  — ${d.rel}:${d.line}`);
console.log(`\n  B) MIS-NAMED CORE (settle closure delegates to a plain _ method): ${misNamedCores.length}`);
for (const h of misNamedCores) console.log(`     ${h.wrapper.klass}.${h.wrapper.method} -> ${h.callee}  — ${h.wrapper.rel}:${h.n}`);
console.log('\n  (advisory census; plain non-settling _ helpers/queries keep their own names by design — Topic 3\'s refinement)');

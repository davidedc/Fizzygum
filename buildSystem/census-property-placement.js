#!/usr/bin/env node
'use strict';
/*
 * census-property-placement.js — the PROPERTY-PLACEMENT census: properties declared at the wrong
 * level of the hierarchy (pull them UP) or at the wrong SCOPE entirely (demote them to a local).
 *
 * ADVISORY, never a gate: always exits 0 (2 only on operational error). Sibling of
 * census-hierarchy-duplication.js (which asks the same "is this in the right place?" question about
 * METHODS) and of census-public-private-calls.js (its engine — the class model is reused from it).
 *
 * Pharo ancestry (carried over 2026-07-15, docs/archive/lint-generic-rules-carryover-plan.md Phase 4):
 *   ReInstVarInSubclassesRule    — the same instance variable declared in every subclass -> pull up
 *   ReVariableReferencedOnceRule — an ivar used in one method, assigned before read -> make it local
 *
 * WHAT IT REPORTS (two reports):
 *   PULL-UP  a property declared in EVERY direct subclass of P but nowhere in P or above it. Strong
 *            when the defaults agree; informational when they differ (that is a shared CONCEPT with
 *            per-subclass values — often still worth a pulled-up declaration, but it is a judgement).
 *   DEMOTE   a property whose every `@prop` use sits inside exactly ONE method, where the first use
 *            is an assignment AND at least one use is a READ, and which no super/subclass touches.
 *            It is a local wearing a field's clothes: it widens the object's state and its
 *            serialization surface for nothing.
 *
 * ── WHY THIS CAN NEVER BE A GATE (severity policy — do not "promote" it) ────────────────────────
 * Property access here is partly DYNAMIC and therefore invisible to a name scanner: DeepCopierMixin
 * walks `@[property]`, and the serialization protocol drives off property-NAME STRINGS. A property
 * whose name appears in a string may be read by machinery this census cannot see, so "unused" is
 * never provable statically. An unsound signal must never gate.
 *
 * ⚠ KNOWN BLIND SPOT — whole-object ENUMERATION. `JSON.stringify(obj)`, DeepCopierMixin's
 * `@[property]` walk and the serializer reach EVERY own property of an object without ever naming
 * one, so no name scanner can see those reads. Exclusions 1 and 3 only catch properties named by a
 * string or read as a dotted `.member`; enumeration names nothing. This is why exclusion 4 presumes
 * a WRITE-ONLY field is enumeration payload rather than dead code. Do NOT try to detect enumeration
 * statically — that way lies unsoundness; presume in the safe direction instead.
 *
 * ── THE FOUR SAFETY EXCLUSIONS (each has bitten before — do not remove) ─────────────────────────
 * 1. STRING-NAMED properties are dropped entirely. If a property's name appears as a quoted string
 *    ANYWHERE in src or the harness, it may be serialization protocol (`serializationTransients`),
 *    a dynamic `@[property]` walk, or menu/connection dispatch. Same strings-count-as-references
 *    lesson check-dead-methods.js already encodes.
 * 2. WIDGET-FAMILY findings are TAGGED `[inspector-visible]`, not dropped. The inspector renders
 *    live member lists, so adding/removing a FIELD on a class reachable from `Widget` churns
 *    exactly 15 SystemTest screenshots (the `fg recapture-inspector` set — measured empirically
 *    2026-07-12). Any future arc acting on a tagged finding must BUDGET that recapture. This is a
 *    cost tag, not a veto.
 * 3. A `.name` MEMBER READ from another file VETOES a DEMOTE (see MEMBER_FILES below). Withheld,
 *    counted, and printed — never dropped silently.
 * 4. WRITE-ONLY properties are VETOED as DEMOTE candidates (every occurrence is an assignment, none
 *    is a read). Added 2026-07-15, after the original rule shipped without it and produced 16 false
 *    positives out of 36 findings. Demoting a write-only field does not make it a local, it makes it
 *    DEAD — and a write-only field is usually not dead at all, it is enumeration payload (the blind
 *    spot above). The decisive case: 12 of those 16 were `SystemInfo` fields, assigned in the ctor
 *    and never read in src because they are read by `JSON.stringify(@systemInfo)` at
 *    Fizzygum-tests/Automator-and-test-harness-src/SystemTestsReferenceImage.coffee:31, whose hash is
 *    the `systemInfoHash` in EVERY reference-image filename. Acting on them would have invalidated
 *    the entire committed reference set. `SystemTestsSystemInfo.coffee` says the mechanism outright:
 *    "cannot just initialise the numbers here cause we are going to make a JSON out of this and these
 *    would not be picked up" — class-body defaults are PROTOTYPE properties and are not serialized;
 *    only the constructor's `@x = …` OWN properties are. Withheld, counted, and printed.
 *    ⚠ The test is "at least one NON-ASSIGNMENT occurrence", NOT `uses >= 2`: `@x = 0` followed by
 *    `@x += 1` is two uses and still write-only in effect. Compound assignments (`+=`, `?=`, …) do
 *    technically read, but a value only ever fed back into itself is not consumed by anything
 *    observable — so they count as writes here, deliberately, to keep the census conservative.
 *
 * METHOD (heuristics, no type inference — the house style):
 *   - Class model (parent, mixins, methods, chain order) REUSED from census-public-private-calls.js.
 *   - "Declared property" = a 2-space class-body default whose value is not a function
 *     (`bounds: nil`, `color: Color.create 80,80,80`) UNION any `@name = …` instance assignment.
 *   - Method attribution for the DEMOTE report reuses the census's own method boundaries.
 *
 * USAGE (run from the Fizzygum/ repo root, like the gates):
 *   node ./buildSystem/census-property-placement.js [--json out.json] [--full]
 * Exit codes: 0 = ran · 2 = operational error.
 */

const fs = require('fs');
const path = require('path');
const { runCensus, maskLine } = require('./census-public-private-calls.js');

const SRC = path.resolve(__dirname, '../src');
const HARNESS = path.resolve(__dirname, '../../Fizzygum-tests/Automator-and-test-harness-src');
const FULL = process.argv.includes('--full');
const jsonIdx = process.argv.indexOf('--json');
const JSON_OUT = jsonIdx >= 0 ? process.argv[jsonIdx + 1] : null;

let out;
try {
  out = runCensus();
} catch (e) {
  console.error('[property-placement] ERROR — ' + e.message);
  process.exit(2);
}
const { classInfo, chainOf, allMethods } = out;

function collectFiles(dir, ext, acc) {
  if (!fs.existsSync(dir)) return acc;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) collectFiles(p, ext, acc);
    else if (e.name.endsWith(ext)) acc.push(p);
  }
  return acc;
}

// ── exclusions 1 & 3, harvested in one pass over src + harness ──────────────────────────────────
// STRING_WORDS  (exclusion 1) — every word appearing inside a STRING. A property named there may be
//   reached by serialization / a dynamic @[prop] walk / string dispatch: machinery no name scanner
//   can follow.
// MEMBER_FILES  (exclusion 3) — for each name, the files where it appears as a `.name` MEMBER read.
//   A property is only "local to one method" if nothing OUTSIDE reads it, and `@prop` self-scans
//   cannot see a dotted read through a global. Real case: an early cut of this census called 22
//   PreferencesAndSettings fields demotable because each is only ASSIGNED in @setMouseInputMode —
//   but they are the global settings surface, read elsewhere as
//   `WorldWdgt.preferencesAndSettings.defaultPanelsBackgroundColor` (PanelWdgt:22). Demoting one
//   would have broken rendering. So: a `.name` read in ANY OTHER file vetoes the finding.
//   Deliberately conservative — a name scanner cannot tell `slider.offset` from `point.offset`, so a
//   dotted read elsewhere means this census simply CANNOT prove the property is local. Findings lost
//   this way are counted and reported, never dropped silently.
const STRING_WORDS = new Set();
const MEMBER_FILES = new Map();   // name -> Set(relative file paths reading it as `.name`)
{
  const WORD = /[A-Za-z_$][\w$]*/g;
  const MEMBER = /\.([A-Za-z_$][\w$]*)/g;
  for (const f of [...collectFiles(SRC, '.coffee', []), ...collectFiles(HARNESS, '.coffee', [])]) {
    const rel = f.startsWith(SRC) ? path.relative(SRC, f) : 'harness/' + path.relative(HARNESS, f);
    let state = null;
    for (const line of fs.readFileSync(f, 'utf8').split('\n')) {
      const r = maskLine(line, state);
      state = r.state;
      let m;
      WORD.lastIndex = 0;
      while ((m = WORD.exec(line)) !== null) {
        if (r.mask[m.index] === 'str') STRING_WORDS.add(m[0]);
      }
      let code = '';
      for (let k = 0; k < line.length; k++) code += (r.mask[k] === 'code' ? line[k] : ' ');
      MEMBER.lastIndex = 0;
      while ((m = MEMBER.exec(code)) !== null) {
        if (!MEMBER_FILES.has(m[1])) MEMBER_FILES.set(m[1], new Set());
        MEMBER_FILES.get(m[1]).add(rel);
      }
    }
  }
}
// is `prop` read as `.prop` from a file other than its own class's?
function readAsMemberElsewhere(prop, ownFile) {
  const files = MEMBER_FILES.get(prop);
  if (!files) return false;
  for (const f of files) if (f !== ownFile) return true;
  return false;
}

// ── the property harvest ────────────────────────────────────────────────────────────────────────
// A 2-space class-body key whose value is NOT a function arrow is a property DEFAULT. `@name = …`
// anywhere in the class body is an instance assignment. Union = the class's declared properties.
const PROP_DEFAULT = /^  ([A-Za-z_$][\w$]*)\s*:\s*(\S.*?)\s*$/;
const IS_FUNCTION_VALUE = /^(\([^)]*\)\s*)?[-=]>/;
const FIELD_ASSIGN = /@([A-Za-z_$][\w$]*)\s*(\?=|\|\|=|\+=|-=|\*=|\/=|=(?![=>]))/g;

const declared = new Map();   // className -> Map(prop -> { def: string|null, line })
for (const info of classInfo.values()) {
  const props = new Map();
  const raw = fs.readFileSync(path.join(SRC, info.file), 'utf8').split('\n');
  let state = null;
  raw.forEach((line, i) => {
    const r = maskLine(line, state);
    state = r.state;
    let code = '';
    for (let k = 0; k < line.length; k++) if (r.mask[k] !== 'cut') code += line[k];
    if (!code.trim()) return;

    const d = PROP_DEFAULT.exec(code);
    if (d && !IS_FUNCTION_VALUE.test(d[2])) {
      if (!props.has(d[1])) props.set(d[1], { def: d[2], line: i + 1 });
      else if (props.get(d[1]).def === null) props.set(d[1], { def: d[2], line: i + 1 });
    }
    let m;
    FIELD_ASSIGN.lastIndex = 0;
    while ((m = FIELD_ASSIGN.exec(code)) !== null) {
      if (!props.has(m[1])) props.set(m[1], { def: null, line: i + 1 });
    }
  });
  declared.set(info.name, props);
}

// ── hierarchy helpers ───────────────────────────────────────────────────────────────────────────
const directSubs = new Map();   // parentName -> [childName…]
for (const info of classInfo.values()) {
  if (!info.parent) continue;
  if (!directSubs.has(info.parent)) directSubs.set(info.parent, []);
  directSubs.get(info.parent).push(info.name);
}
const descendants = new Map();  // className -> Set(all classes below it)
for (const info of classInfo.values()) {
  for (const anc of chainOf(info.name)) {
    if (anc.name === info.name) continue;
    if (!descendants.has(anc.name)) descendants.set(anc.name, new Set());
    descendants.get(anc.name).add(info.name);
  }
}
const isWidgetFamily = (cls) => chainOf(cls).some((i) => i.name === 'Widget');
// declared anywhere at-or-above `cls` (own included when own=true)
function declaredAtOrAbove(cls, prop, includeOwn) {
  for (const info of chainOf(cls)) {
    if (!includeOwn && info.name === cls) continue;
    const p = declared.get(info.name);
    if (p && p.has(prop)) return info.name;
  }
  return null;
}

// ── REPORT 1: PULL-UP ───────────────────────────────────────────────────────────────────────────
const pullUp = [];
for (const [parent, subs] of directSubs) {
  if (subs.length < 2) continue;
  if (!classInfo.has(parent)) continue;
  const counts = new Map();   // prop -> [ {cls, def} … ]
  for (const s of subs) {
    for (const [prop, rec] of declared.get(s) || []) {
      if (!counts.has(prop)) counts.set(prop, []);
      counts.get(prop).push({ cls: s, def: rec.def });
    }
  }
  for (const [prop, rows] of counts) {
    if (rows.length !== subs.length) continue;                  // not in EVERY direct subclass
    if (STRING_WORDS.has(prop)) continue;                       // exclusion 1
    if (declaredAtOrAbove(parent, prop, true)) continue;        // parent (or above) already has it
    const defs = rows.map((r) => r.def);
    const same = defs.every((d) => d !== null && d === defs[0]);
    pullUp.push({
      prop, parent, k: subs.length, same,
      def: same ? defs[0] : null,
      subs: rows.map((r) => r.cls),
      inspectorVisible: isWidgetFamily(parent),
    });
  }
}
pullUp.sort((a, b) => b.k - a.k || (a.same === b.same ? 0 : a.same ? -1 : 1) || (a.parent + a.prop < b.parent + b.prop ? -1 : 1));

// ── REPORT 2: DEMOTE ────────────────────────────────────────────────────────────────────────────
// method boundaries come straight from the census
const methodsByClass = new Map();
for (const rec of allMethods) {
  if (!methodsByClass.has(rec.cls)) methodsByClass.set(rec.cls, []);
  methodsByClass.get(rec.cls).push(rec);
}

// Occurrences are scanned over the WHOLE FILE and attributed to the enclosing method by LINE;
// anything outside every method body is attributed to the pseudo-owner '@classlevel'.
//
// Why not just walk the census's bodyLines? Because a use can live in a place no method body covers
// — above all a MULTI-LINE CONSTRUCTOR PARAMETER LIST. CoffeeScript's `constructor: (@elements = [],
// @labelGetter = …) ->` auto-assigns from the CALLER, which makes the property public API, the exact
// opposite of demotable. Real case: an early cut of this census called ListWdgt.elements demotable
// — wrong; `new ListWdgt(someElements)` is how it is fed. Attributing such a line to '@classlevel'
// makes it a second user, so the finding correctly disappears. (Same lesson as
// check-constructors-build.js's `inctor` state machine, which is multi-line-ctor-header aware.)
const lineOwnersCache = new Map();
function lineOwnerOf(clsName) {
  let map = lineOwnersCache.get(clsName);
  if (map) return map;
  map = new Map();   // 1-based line -> method name
  for (const rec of methodsByClass.get(clsName) || []) {
    for (const b of rec.bodyLines) map.set(b.n, rec.name);
  }
  lineOwnersCache.set(clsName, map);
  return map;
}
// every line of the class file with comments AND strings removed (a @prop inside a string is not a
// code use — and any string-named property was dropped by exclusion 1 anyway)
const codeLinesCache = new Map();
function codeLinesOf(relFile) {
  let lines = codeLinesCache.get(relFile);
  if (lines) return lines;
  const raw = fs.readFileSync(path.join(SRC, relFile), 'utf8').split('\n');
  let state = null;
  lines = raw.map((line) => {
    const r = maskLine(line, state);
    state = r.state;
    let out = '';
    for (let i = 0; i < line.length; i++) out += (r.mask[i] === 'code' ? line[i] : ' ');
    return out;
  });
  codeLinesCache.set(relFile, lines);
  return lines;
}
const isAssignmentAfter = (code, endIdx) => /^\s*(\?|\|\||\+|-|\*|\/)?=(?![=>])/.test(code.slice(endIdx));
// does any class in `names` mention @prop ANYWHERE in its file (same whole-file scan as above — a
// relative touching the property in a multi-line signature must veto the demotion too), or declare it?
function anyMentions(names, prop) {
  const re = new RegExp('@' + prop + '\\b');
  for (const n of names) {
    const info = classInfo.get(n);
    if (info && codeLinesOf(info.file).some((code) => re.test(code))) return true;
    const p = declared.get(n);
    if (p && p.has(prop)) return true;
  }
  return false;
}

const demote = [];
let vetoedByMemberRead = 0;
let vetoedByWriteOnly = 0;
for (const info of classInfo.values()) {
  const props = declared.get(info.name) || new Map();
  const recs = methodsByClass.get(info.name) || [];
  for (const [prop, rec0] of props) {
    if (STRING_WORDS.has(prop)) continue;                                  // exclusion 1
    // no super/subclass may touch it
    const supers = chainOf(info.name).map((i) => i.name).filter((n) => n !== info.name);
    const subs = [...(descendants.get(info.name) || [])];
    if (anyMentions([...supers, ...subs], prop)) continue;

    // every @prop occurrence must sit in exactly ONE method of this class
    const re = new RegExp('@' + prop + '\\b', 'g');
    const owners = lineOwnerOf(info.name);
    const users = new Map();   // methodName (or '@classlevel') -> [{n, code, end}]
    codeLinesOf(info.file).forEach((code, idx) => {
      re.lastIndex = 0;
      let m;
      while ((m = re.exec(code)) !== null) {
        const owner = owners.get(idx + 1) || '@classlevel';
        if (!users.has(owner)) users.set(owner, []);
        users.get(owner).push({ n: idx + 1, code, end: m.index + m[0].length });
      }
    });
    if (users.size !== 1) continue;
    const [method, hits] = [...users][0];
    if (method === '@classlevel') continue;   // not confined to a method at all
    hits.sort((a, b) => a.n - b.n || a.end - b.end);
    if (!isAssignmentAfter(hits[0].code, hits[0].end)) continue;           // first use must be a write
    // exclusion 4 — a property->local needs a WRITE *and* a READ. If every occurrence is an
    // assignment the field is WRITE-ONLY: demoting it would make it dead, not local, and it is far
    // more likely enumeration payload this scanner cannot see (see the header). Checked BEFORE
    // exclusion 3 so that each withheld counter keeps a clean meaning.
    const reads = hits.filter((h) => !isAssignmentAfter(h.code, h.end)).length;
    if (reads === 0) { vetoedByWriteOnly++; continue; }
    // exclusion 3 LAST, so the withheld count means "real findings this exclusion cost us", not
    // "properties it happened to touch"
    if (readAsMemberElsewhere(prop, info.file)) { vetoedByMemberRead++; continue; }
    demote.push({
      cls: info.name, prop, method,
      at: `${info.file}:${hits[0].n}`,
      uses: hits.length,
      reads,
      hasDefault: rec0.def !== null,
      inspectorVisible: isWidgetFamily(info.name),
    });
  }
}
demote.sort((a, b) => b.uses - a.uses || (a.cls + a.prop < b.cls + b.prop ? -1 : 1));

// ── report ──────────────────────────────────────────────────────────────────────────────────────
const trunc = (arr, n) => (FULL ? arr : arr.slice(0, n));
const tag = (r) => (r.inspectorVisible ? '  [inspector-visible]' : '');

console.log('=== census-property-placement ===');
console.log(`scanned ${classInfo.size} classes; ${[...declared.values()].reduce((a, m) => a + m.size, 0)} declared properties; ${STRING_WORDS.size} names excluded as string-reachable`);
console.log(`PULL-UP: ${pullUp.length} (${pullUp.filter((r) => r.same).length} same-default)   DEMOTE: ${demote.length}`);
console.log('\nADVISORY — nothing here gates. Property access is partly DYNAMIC (DeepCopierMixin walks');
console.log('@[property]; serialization drives off name STRINGS), so "unused" is never provable statically.');
console.log('[inspector-visible] = the class is Widget-family: acting on it churns the 15-screenshot');
console.log('`fg recapture-inspector` set. That is a COST to budget, not a veto.');

console.log(`\n--- PULL-UP (${pullUp.length}) — declared in every direct subclass, absent from the parent ---`);
for (const r of trunc(pullUp, 40)) {
  console.log(`  PULL-UP  ${r.prop}: declared in ${r.k}/${r.k} subclasses of ${r.parent} (defaults: ${r.same ? 'same -> ' + r.def : 'differing'})${tag(r)}`);
  console.log(`             subclasses: ${r.subs.join(', ')}`);
}
if (!FULL && pullUp.length > 40) console.log(`  … ${pullUp.length - 40} more (--full)`);

console.log(`\n--- DEMOTE (${demote.length}) — property -> local (one method, written and read there only) ---`);
console.log(`    (${vetoedByMemberRead} candidate${vetoedByMemberRead === 1 ? '' : 's'} withheld: read as \`.name\` from another file, so locality is not provable — see exclusion 3)`);
console.log(`    (${vetoedByWriteOnly} candidate${vetoedByWriteOnly === 1 ? '' : 's'} withheld: WRITE-ONLY — never read, so presumed enumeration payload, not a local — see exclusion 4)`);
for (const r of trunc(demote, 40)) {
  console.log(`  DEMOTE  ${r.cls}.${r.prop}: only used in @${r.method} (${r.uses} use${r.uses === 1 ? '' : 's'}, ${r.reads} read${r.reads === 1 ? '' : 's'}${r.hasDefault ? ', has a class-body default' : ''})  ${r.at}${tag(r)}`);
}
if (!FULL && demote.length > 40) console.log(`  … ${demote.length - 40} more (--full)`);

if (JSON_OUT) {
  fs.writeFileSync(JSON_OUT, JSON.stringify({ pullUp, demote }, null, 1));
  console.log('\n[property-placement] JSON written to ' + JSON_OUT);
}
process.exit(0);

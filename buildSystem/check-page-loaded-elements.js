#!/usr/bin/env node
'use strict';
// check-page-loaded-elements.js — build gate: AN ELEMENT THE PAGE LOADS IS A PAGE FACT.
//
// An image or a video a widget loads is an element of THIS page, made from a path the widget holds: the
// page resolves the path against where the page itself lives and decodes what it finds there. Neither
// fact travels. A saved file that carried the element would carry where the SAVING page found it — an
// absolute file:// path, or a blob: URL that dies with its session — and a copy that carried it would get
// an element none of the original's load handlers are attached to, so the copy would claim (or wait for)
// a load it never made. So neither walker carries one: the Serializer has no encoder for an element and
// refuses one, the Duplicator leaves the clone's field undefined, and the HOLDER re-makes the element,
// with its handlers, from its own path field (serialization-duplication-reference.md §5, §6).
//
// THE RULE. Every `@field` a class ASSIGNS an element the page loads — `new Image`, `new Audio` (with or
// without `window.` and parentheses), `document.createElement` of an "img", "video" or "audio" (with or
// without parentheses, either quote) — must be
//   (a) a serialization transient of the class chain: the class's own `@serializationTransients` plus
//       every ancestor's, walked up `extends` (the source-level twin of boot's
//       classStaticListMergedUpTheChain, which reads each class's OWN list and walks on past it); and
//   (b) re-made by the class chain: it defines BOTH `_afterDeserialization` (a restore) and
//       `_reactToBeingCopied` (a copy) as instance methods — on the class or an ancestor.
// An element constructed on a line that assigns it to no field is not attributable to a field, and is
// refused unless the line, or the contiguous comment block directly above it, says why no widget holds it:
//     # page-element-not-held: <reason>
// (reason required) — the shape is the Deserializer's $Canvas decoder, a local image that decodes a
// record's own data: URL and is dropped.
//
// IT READS ALL OF THE COMPILED SOURCES (lib/source-files.js compiledFiles: src/ and the tests repo's harness), every
// part, shipped or not.
// Method grouping is the shared buildSystem/lib/coffee-method-header.js (methodSpans), so a class-side key
// bounds a method exactly as every other gate sees it.
//
// BLIND SPOTS (stated, not silent):
//   - an element reached without construction syntax on the line: a write through an alias
//     (`img = new Image()` on one line, `@img = img` on the next — the first line is refused as
//     unattributed, so this cannot pass silently), an element handed in from outside (a parameter, a
//     DOM query), or one made by a helper in another file and returned — the helper's own line is
//     unattributed and refused, but the field the caller stores it in is not followed.
//   - an element stored INTO a field's contents (`@a.b = new Image`, `@a[i] = …`, a Map/Set) rather than
//     into a field: neither walker sees the field itself as the element, and this scanner does not
//     follow the write.
//   - a hook that exists but does not re-make the element: (b) asks that the chain DEFINES both hooks,
//     not what their bodies do.
// One shape it refuses LOUDLY rather than skipping: a hook header written in a spelling the shared matcher
// cannot see (unseenMethodHeaders) — a gate blind to a method reports nothing about it, so blindness is
// made a failure.
//
// Exit codes: 0 clean · 1 violation · 2 operational (no src/, or not one element construction found — a
// run that checked nothing is not a pass).
// Run from the Fizzygum/ repo root (build_it_please.sh does): node ./buildSystem/check-page-loaded-elements.js [--src=DIR]
// [--tests-repo=DIR]
// That it BITES is proven on every build by check-page-loaded-elements-selftest.js: the real gate, on a copy of src/
// carrying one throwaway widget per clause — an element field not transient, a missing restore hook, a missing copy
// hook, an element assigned to no field — must fail naming each, and the declared forms must pass
// (lib/planted-src.js).

const fs = require('fs');
const path = require('path');
const { methodSpans, unseenMethodHeaders } = require('./lib/coffee-method-header.js');
const { coffeeMask, isCommentOnly } = require('./lib/coffee-mask');

const { rejectUnknownArgs, rejectPositionalArgs } = require('./lib/cli-args');
const { coffeeFilesIn, compiledFiles, sourceRoots, sourceName, SOURCE_RAILS } = require('./lib/source-files');
const rules = require('./lib/gate-rules').forGate(__filename);
// --src=DIR / --tests-repo=DIR check another src tree / tests repo in place of this umbrella's: a copy carrying a plant
// (the self-test's rail)
const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, [...SOURCE_RAILS], 'check-page-loaded-elements');
rejectPositionalArgs(ARGV, 'check-page-loaded-elements', 'a src tree is named with --src=DIR');
const ROOTS = sourceRoots(ARGV, 'check-page-loaded-elements');
const SRC = ROOTS.src;
// hand-list-sanctioned: check-page-loaded-elements.js — a hook renamed in its holders fails each as
// "the class chain defines no <hook>"; one renamed at its walker's call site fails as "neither walker calls"
const HOOKS = ['_afterDeserialization', '_reactToBeingCopied'];
const NOT_HELD_MARKER = /#\s*page-element-not-held:\s*\S/;
const ELEMENT = String.raw`(?:new\s+(?:window\.)?(?:Image|Audio)\b|document\.createElement\s*\(?\s*['"](?:img|video|audio)['"])`;
const ELEMENT_RE = new RegExp(ELEMENT, 'i');
// a field written with an element: `@f = <element>`, or one link of a chained assignment that ends in one
// (`img = @f = new Image()`)
const FIELD_WRITE_RE = new RegExp(String.raw`@([A-Za-z_]\w*)\s*=(?!=)\s*(?:@?[A-Za-z_][\w.]*\s*=(?!=)\s*)*` + ELEMENT, 'gi');

// The names a class-level list declaration holds — `@serializationTransients: [ … ]` — read through to its
// closing bracket. The brackets are found in the line's bare code (a `]` inside a string closes nothing) and the names read from its code
// (comment blanked), so a quoted word in a comment is not taken for a name.
function listDeclaration(lines, masked, key) {
  const head = new RegExp('^\\s*' + key + ':\\s*\\[');
  const start = lines.findIndex((l) => head.test(l));
  if (start < 0) return [];
  const out = [];
  for (let j = start; j < lines.length; j++) {
    const { bare, code } = masked[j];
    const from = j === start ? bare.indexOf('[') + 1 : 0;
    const close = bare.indexOf(']', from);
    const span = code.slice(from, close >= 0 ? close : code.length);
    const re = /"([^"]+)"|'([^']+)'/g;
    let m;
    while ((m = re.exec(span))) out.push(m[1] || m[2]);
    if (close >= 0) break;
  }
  return out;
}

// the line, or the contiguous comment block directly above it, carries the not-held marker
function markedNotHeld(masked, i) {
  const marked = (j) => NOT_HELD_MARKER.test(masked[j].comment || '');
  if (marked(i)) return true;
  for (let j = i - 1; j >= 0 && isCommentOnly(masked[j]); j--) if (marked(j)) return true;
  return false;
}

if (!fs.existsSync(SRC)) { console.error('[page-loaded-elements] operational error: no src/ at ' + SRC); process.exit(2); }

const classes = {};   // name -> { file, sup, transients:Set, methods:Set, fields:[{field, at, text}] }
const problems = [];
const unattributed = [];
let constructions = 0, notHeld = 0;
const maskedFiles = new Map();   // each compiled source's lib/coffee-mask.js reading (the walkers' too, read below)
for (const p of compiledFiles(ROOTS)) {
  const text = fs.readFileSync(p, 'utf8');
  const lines = text.split('\n');
  const file = sourceName(p, ROOTS);
  const masked = coffeeMask(text, file);
  maskedFiles.set(p, masked);
  const spans = methodSpans(lines);
  for (const u of unseenMethodHeaders(lines, masked)) {
    if (HOOKS.some((h) => u.text.startsWith(h))) problems.push(rules.fired('UNSEEN_HOOK_HEADER', `  ${file}:${u.line}  a hook header in a spelling the shared matcher cannot see — this gate would be blind to it: ${u.text}`));
  }
  // every element construction in the file, attributed to the field it is written to (or to none)
  const writes = [];
  lines.forEach((raw, i) => {
    const code = masked[i].code;            // strings kept: a tag name is a string ("video")
    if (!ELEMENT_RE.test(code)) return;
    constructions++;
    const fields = [];
    let m;
    FIELD_WRITE_RE.lastIndex = 0;
    while ((m = FIELD_WRITE_RE.exec(code))) fields.push(m[1]);
    if (!fields.length) {
      if (markedNotHeld(masked, i)) notHeld++;
      else unattributed.push(rules.fired('UNATTRIBUTED_ELEMENT', `  ${file}:${i + 1}  ${raw.trim()}`));
      return;
    }
    for (const f of fields) writes.push({ field: f, at: `${file}:${i + 1}`, text: raw.trim() });
  });
  const cm = lines.map((l) => l.match(/^class\s+(\w+)(?:\s+extends\s+(\w+))?/)).find(Boolean);
  if (cm) {
    classes[cm[1]] = {
      file, sup: cm[2],
      transients: new Set(listDeclaration(lines, masked, '@serializationTransients')),
      methods: new Set(spans.filter((s) => !s.static).map((s) => s.name)),
      fields: writes,
    };
  }
}

// the chain's merged transients and instance methods
function chainSets(name) {
  const transients = new Set(), methods = new Set(), seen = new Set();
  for (let c = name; c && classes[c] && !seen.has(c); c = classes[c].sup) {
    seen.add(c);
    const k = classes[c];
    k.transients.forEach((x) => transients.add(x));
    k.methods.forEach((x) => methods.add(x));
  }
  return { transients, methods };
}

const violations = [];
const holders = new Set();
for (const [name, k] of Object.entries(classes)) {
  if (!k.fields.length) continue;
  const { transients, methods } = chainSets(name);
  const missingHooks = HOOKS.filter((h) => !methods.has(h));
  for (const w of k.fields) {
    holders.add(`${name}.${w.field}`);
    const why = [];
    if (!transients.has(w.field)) why.push(`not a serialization transient of the class chain`);
    if (missingHooks.length) why.push(`the class chain defines no ${missingHooks.join(' and no ')}`);
    if (why.length) violations.push({ name, field: w.field, at: w.at, text: w.text, why,
      notTransient: !transients.has(w.field), noRestore: missingHooks.includes(HOOKS[0]), noCopy: missingHooks.includes(HOOKS[1]) });
  }
}

// EACH HOOK IS ONE A WALKER CALLS — the Deserializer after a restore, the Duplicator after a copy — so a
// hook renamed at its call site, which would leave every holder's re-make uncalled, fails here too
const WALKERS = [path.join(SRC, 'serialization'), path.join(SRC, 'duplication')];
for (const h of HOOKS) {
  const call = new RegExp(String.raw`\.${h}\??\(`);
  const called = WALKERS.some((d) => fs.existsSync(d) && coffeeFilesIn(d).some((f) => maskedFiles.get(f).some((l) => call.test(l.code))));
  if (!called) problems.push(rules.fired('HOOK_NOT_CALLED', `  HOOKS names ${h}, which neither walker (src/serialization, src/duplication) calls — a holder defining it re-makes nothing`));
}

if (problems.length) {
  console.error('\n[page-loaded-elements] FAIL — shapes this gate refuses to be blind to:');
  for (const p of problems) console.error(p);
}
if (constructions === 0) {
  console.error('[page-loaded-elements] operational error: not one element construction found under ' + SRC + ' — a run that checked nothing is not a pass.');
  process.exit(2);
}
console.log(`[page-loaded-elements] ${constructions} element construction(s) across ${Object.keys(classes).length} classes: ` +
  `${constructions - notHeld - unattributed.length} assigned to ${holders.size} field(s) (${[...holders].sort().join(', ') || 'none'}), ${notHeld} declared not held.`);
let failed = problems.length > 0;
if (violations.length) {
  failed = true;
  console.error(`\n[page-loaded-elements] FAIL — ${violations.length} field(s) holding an element the page loads that a save or a copy would carry:`);
  for (const v of violations) {
    // one line per violating field; each clause it breaks is its own rule
    let line = `  ${v.name}.${v.field}  (${v.at}) — ${v.why.join('; ')}`;
    if (v.notTransient) line = rules.fired('NOT_TRANSIENT', line);
    if (v.noRestore) line = rules.fired('NO_RESTORE_HOOK', line);
    if (v.noCopy) line = rules.fired('NO_COPY_HOOK', line);
    console.error(line);
    console.error(`    ${v.text}`);
  }
}
if (unattributed.length) {
  failed = true;
  console.error(`\n[page-loaded-elements] FAIL — ${unattributed.length} element construction(s) assigned to no field, so no field can be checked:`);
  for (const u of unattributed) console.error(u);
}
if (failed) {
  console.error('\nAn element the page loads is derived from its holder\'s path: keep the path in a field, declare the field');
  console.error('holding the element in the class\'s @serializationTransients, and re-make the element from the path in');
  console.error('_afterDeserialization and _reactToBeingCopied. An element no widget holds says why on its line:');
  console.error('  # page-element-not-held: <reason>');
  process.exit(1);
}
console.log('[page-loaded-elements] OK — every element the page loads is a transient its holder re-makes after a restore and a copy.');
process.exit(0);

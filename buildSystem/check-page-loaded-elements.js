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
//       classStaticListMergedUpTheChain, which reads each class's OWN list and walks on past it), a
//       mixin's class-side `serializationTransients` counted at each class that `@augmentWith`s it; and
//   (b) re-made by the class chain: it defines BOTH `_afterDeserialization` (a restore) and
//       `_reactToBeingCopied` (a copy) as instance methods — on the class, an ancestor, or a mixin the
//       class or an ancestor augments with.
// An element constructed on a line that assigns it to no field is not attributable to a field, and is
// refused unless the line, or the contiguous comment block directly above it, says why no widget holds it:
//     # page-element-not-held: <reason>
// (reason required) — the shape is the Deserializer's $Canvas decoder, a local image that decodes a
// record's own data: URL and is dropped.
//
// IT READS ALL OF src/, every part, shipped or not: both element holders live in the flag-gated
// `video-player` part, which no default build carries and so no suite, rig or smoke runs.
// Method grouping is the shared buildSystem/lib/coffee-method-header.js (methodSpans), so a mixin member
// or a class-side key bounds a method exactly as every other gate sees it.
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
// Two shapes it refuses LOUDLY rather than skipping: an element field assigned inside a MIXIN member (its
// transients and its hooks are its consumers', which a per-file scan cannot resolve), and a hook header
// written in a spelling the shared matcher cannot see (unseenMethodHeaders) — a gate blind to a method
// reports nothing about it, so blindness is made a failure.
//
// Exit codes: 0 clean · 1 violation · 2 operational (no src/, or not one element construction found — a
// run that checked nothing is not a pass).
// Run from the Fizzygum/ repo root (build_it_please.sh does): node ./buildSystem/check-page-loaded-elements.js
// [srcDir] — the optional argument checks another src tree (a copy carrying a revert plant).
// Revert plants: drop "img" from SimpleImageWdgt's @serializationTransients, or delete its
// _reactToBeingCopied or its _afterDeserialization, or drop "video" from VideoPlayerCanvasWdgt's — each
// fails the gate naming the class and the field; delete the page-element-not-held line above the
// Deserializer's decoder and it fails as unattributed.

const fs = require('fs');
const path = require('path');
const { methodSpans, unseenMethodHeaders } = require('./lib/coffee-method-header.js');

const SRC = path.resolve(process.argv[2] || path.resolve(__dirname, '../src'));
const HOOKS = ['_afterDeserialization', '_reactToBeingCopied'];
const NOT_HELD_MARKER = /#\s*page-element-not-held:\s*\S/;
const ELEMENT = String.raw`(?:new\s+(?:window\.)?(?:Image|Audio)\b|document\.createElement\s*\(?\s*['"](?:img|video|audio)['"])`;
const ELEMENT_RE = new RegExp(ELEMENT, 'i');
// a field written with an element: `@f = <element>`, or one link of a chained assignment that ends in one
// (`img = @f = new Image()`)
const FIELD_WRITE_RE = new RegExp(String.raw`@([A-Za-z_]\w*)\s*=(?!=)\s*(?:@?[A-Za-z_][\w.]*\s*=(?!=)\s*)*` + ELEMENT, 'gi');

function walk(dir, acc) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (e.name.endsWith('.coffee')) acc.push(p);
  }
  return acc;
}

// The line with its comment removed and its strings KEPT (a tag name is a string: "video"). Quotes are
// tracked so a `#` inside a string (`"#{x}"`) is not taken for a comment.
function withoutComment(line) {
  let out = '', q = null;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (q) {
      if (ch === '\\') { out += ch + (line[i + 1] || ''); i++; continue; }
      if (ch === q) q = null;
      out += ch;
      continue;
    }
    if (ch === '"' || ch === "'") { q = ch; out += ch; continue; }
    if (ch === '#') break;
    out += ch;
  }
  return out;
}

// The names a class-level list declaration holds — `@serializationTransients: [ … ]` (the key spelled
// with or without the `@`: without is a mixin's class-side form) — read through to its closing bracket,
// each line's comment dropped first so a quoted word in a comment is not taken for a name.
function listDeclaration(lines, key) {
  const head = new RegExp('^\\s*' + key + ':\\s*\\[');
  const start = lines.findIndex((l) => head.test(l));
  if (start < 0) return [];
  const out = [];
  for (let j = start; j < lines.length; j++) {
    const code = withoutComment(lines[j]);
    const from = j === start ? code.indexOf('[') + 1 : 0;
    const close = code.indexOf(']', from);
    const span = code.slice(from, close >= 0 ? close : code.length);
    const re = /"([^"]+)"|'([^']+)'/g;
    let m;
    while ((m = re.exec(span))) out.push(m[1] || m[2]);
    if (close >= 0) break;
  }
  return out;
}

// the line, or the contiguous comment block directly above it, carries the not-held marker
function markedNotHeld(lines, i) {
  if (NOT_HELD_MARKER.test(lines[i])) return true;
  for (let j = i - 1; j >= 0 && /^\s*#/.test(lines[j]); j--) if (NOT_HELD_MARKER.test(lines[j])) return true;
  return false;
}

if (!fs.existsSync(SRC)) { console.error('[page-loaded-elements] operational error: no src/ at ' + SRC); process.exit(2); }

const classes = {};   // name -> { file, sup, transients:Set, methods:Set, augments:[], fields:[{field, at, text}] }
const mixins = {};    // name -> { file, transients:Set, methods:Set }
const problems = [];
const unattributed = [];
let constructions = 0, notHeld = 0;
for (const p of walk(SRC, [])) {
  const lines = fs.readFileSync(p, 'utf8').split('\n');
  const file = path.relative(SRC, p);
  const spans = methodSpans(lines);
  for (const u of unseenMethodHeaders(lines)) {
    if (HOOKS.some((h) => u.text.startsWith(h))) problems.push(`  ${file}:${u.line}  a hook header in a spelling the shared matcher cannot see — this gate would be blind to it: ${u.text}`);
  }
  // every element construction in the file, attributed to the field it is written to (or to none)
  const writes = [];
  lines.forEach((raw, i) => {
    const code = withoutComment(raw);
    if (!ELEMENT_RE.test(code)) return;
    constructions++;
    const fields = [];
    let m;
    FIELD_WRITE_RE.lastIndex = 0;
    while ((m = FIELD_WRITE_RE.exec(code))) fields.push(m[1]);
    if (!fields.length) {
      if (markedNotHeld(lines, i)) notHeld++;
      else unattributed.push(`  ${file}:${i + 1}  ${raw.trim()}`);
      return;
    }
    const inMixinMember = spans.some((s) => s.mixin && i > s.line && i < s.end);
    for (const f of fields) writes.push({ field: f, at: `${file}:${i + 1}`, text: raw.trim(), inMixinMember });
  });
  const cm = lines.map((l) => l.match(/^class\s+(\w+)(?:\s+extends\s+(\w+))?/)).find(Boolean);
  if (cm) {
    classes[cm[1]] = {
      file, sup: cm[2],
      transients: new Set(listDeclaration(lines, '@serializationTransients')),
      methods: new Set(spans.filter((s) => !s.static && !s.mixin).map((s) => s.name)),
      augments: lines.map((l) => l.match(/^  @augmentWith\s+(\w+)/)).filter(Boolean).map((m) => m[1]),
      fields: writes,
    };
    continue;
  }
  const mm = lines.map((l) => l.match(/^(\w+)\s*=\s*$/)).find(Boolean);
  if (mm && spans.some((s) => s.mixin)) {
    mixins[mm[1]] = { file, transients: new Set(listDeclaration(lines, 'serializationTransients')), methods: new Set(spans.filter((s) => s.mixin).map((s) => s.name)) };
    for (const w of writes) if (w.inMixinMember) problems.push(`  ${w.at}  an element field (@${w.field}) assigned in the mixin ${mm[1]} — its transients and hooks are its consumers', which this gate cannot resolve per file`);
  }
}

// the chain's merged transients and instance methods, a class's mixins counted at its own step
function chainSets(name) {
  const transients = new Set(), methods = new Set(), seen = new Set();
  for (let c = name; c && classes[c] && !seen.has(c); c = classes[c].sup) {
    seen.add(c);
    const k = classes[c];
    k.transients.forEach((x) => transients.add(x));
    k.methods.forEach((x) => methods.add(x));
    for (const mx of k.augments) if (mixins[mx]) { mixins[mx].transients.forEach((x) => transients.add(x)); mixins[mx].methods.forEach((x) => methods.add(x)); }
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
    if (why.length) violations.push({ name, field: w.field, at: w.at, text: w.text, why });
  }
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
    console.error(`  ${v.name}.${v.field}  (${v.at}) — ${v.why.join('; ')}`);
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

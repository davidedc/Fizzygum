#!/usr/bin/env node
'use strict';
// check-back-buffer-memos.js — build gate: A WIDGET KEEPS NO MEMO OF ITS BACK BUFFER.
//
// A widget's back buffer is a Widget serialization transient (`backBuffer` in Widget's
// @serializationTransients): on almost every widget it is a render cache the next paint
// re-derives, so it never rides a save. A field that records what was painted INTO it — "the size I
// last painted my image at", "the background is already laid" — describes that transient, and if the
// field itself rides the save, the restored widget meets a fresh, unpainted raster together with a
// memo claiming the paint is done, and skips it: an image widget that remembers the size it last
// painted at comes back BLACK, a video canvas that remembers its letterbox is laid comes back with the
// letterbox in its paper colour. The cure is to keep no memo — ask the raster (CanvasWdgt hands over a
// NEW raster exactly when there was none or the size changed) or paint unconditionally — and this gate
// keeps the memo out.
//
// THE RULE. Every `@field` ASSIGNED in a class's back-buffer builder (`_createRefreshOrGetBackBuffer`),
// or in a method of the same file that the builder reaches through `@name` references (transitively),
// must be EITHER
//   - a serialization transient of the class chain: the class's own `@serializationTransients` plus
//     every ancestor's, walked up `extends` — the source-level twin of boot's
//     classStaticListMergedUpTheChain, which reads each class's OWN list and walks on past it, because
//     `extend` copies statics down and a subclass's own list REPLACES that copy at runtime; or
//   - a field the class chain DECLARES as saved content: the declaration line carries, on itself or in
//     the contiguous comment block directly above it,
//         # saved-content: <what makes it content>
//     (reason required). It is a declaration of what the field IS, not a sanction of a defect — the
//     shape is CanvasWdgt.drawnRaster: the very canvas the back buffer holds, held a second time under a
//     name that rides the save because once a pen has drawn on it, it is the drawing's only copy
//     (serialization-duplication-reference.md §5).
//
// A KEYED BUILDER is read for its own body only. A builder that answers from
// `world.cacheForImmutableBackBuffers` (StringWdgt, TextWdgt, PaletteWdgt) owns no per-instance raster
// at all: its buffer is looked up by a KEY built from everything that shapes it, so there is nothing a
// memo could describe. What such a builder reaches is the text layout (reflowText and the fitting
// helpers), whose fields are layout RESULTS computed from saved inputs and recomputed for every buffer
// the key misses — following it would report them as memos, which they are not.
//
// IT READS ALL OF THE COMPILED SOURCES (lib/source-files.js compiledFiles: src/ and the tests repo's harness), every
// part, shipped or not — a build that does not ship a part still checks its code.
// Method grouping is the shared buildSystem/lib/coffee-method-header.js (methodSpans), so a class-side
// key bounds a method exactly as every other gate sees it.
//
// BLIND SPOTS (stated, not silent):
//   - a memo written by a method the builder does NOT reach: an onload/step/event handler that records
//     "already loaded" or "already painted" — an `imageLoaded` flag written in an Image's onload
//     closure is that shape: it must be a serialization transient by declaration, and this gate would
//     not notice if it were not.
//   - methods reached across files (an ancestor's method the builder calls) and dynamic
//     sends (`@[name]()`, a call through another receiver) are not followed; nor is anything a keyed
//     builder reaches (above).
//   - a write through an alias (`self = @`, `that.x = …`) or into a field's contents (`@a.b = …`,
//     `@a[i] = …`) is not a field assignment to this scanner.
//   - a memo in a paint path that is not a back-buffer builder (an appearance's paint, a blit) — those
//     widgets keep no raster to describe, but a future one that did would need its own root here.
// One shape it refuses LOUDLY rather than skipping: a builder header written in a spelling the shared
// matcher cannot see (unseenMethodHeaders) — a gate blind to a method reports nothing about it, so
// blindness is made a failure.
//
// Exit codes: 0 clean · 1 violation · 2 operational (no src/, or not one builder found — a run that
// checked nothing is not a pass).
// Run from the Fizzygum/ repo root (build_it_please.sh does): node ./buildSystem/check-back-buffer-memos.js [--src=DIR]
// [--tests-repo=DIR]
// That it BITES is proven on every build by check-back-buffer-memos-selftest.js: the real gate, on a copy of src/
// carrying a throwaway widget whose builder records a memo, must fail naming the field, and the same field declared
// a transient, or saved content, must pass (lib/planted-src.js).

const fs = require('fs');
const path = require('path');
const { methodSpans, unseenMethodHeaders } = require('./lib/coffee-method-header.js');
const { coffeeMask, isCommentOnly } = require('./lib/coffee-mask');

const { rejectUnknownArgs, rejectPositionalArgs } = require('./lib/cli-args');
const { compiledFiles, sourceRoots, sourceName, SOURCE_RAILS } = require('./lib/source-files');
const rules = require('./lib/gate-rules').forGate(__filename);
// --src=DIR / --tests-repo=DIR check another src tree / tests repo in place of this umbrella's: a copy carrying a plant
// (the self-test's rail)
const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, [...SOURCE_RAILS], 'check-back-buffer-memos');
rejectPositionalArgs(ARGV, 'check-back-buffer-memos', 'a src tree is named with --src=DIR');
const ROOTS = sourceRoots(ARGV, 'check-back-buffer-memos');
const SRC = ROOTS.src;
const BUILDER = '_createRefreshOrGetBackBuffer';
const CONTENT_MARKER = /#\s*saved-content:\s*\S/;

// The names a class-level list declaration holds — `@serializationTransients: [ … ]` — read through to
// its closing bracket.
// The brackets are found in the line's bare code (a `]` inside a string closes nothing) and the names read from
// its code (comment blanked), so a quoted word in a comment is not taken for a name.
function listDeclaration(lines, masked, key) {
  const head = new RegExp('^  ' + key + ':\\s*\\[');
  const start = lines.findIndex((l) => head.test(l));
  if (start < 0) return [];
  const out = [];
  for (let j = start; j < lines.length; j++) {
    const { bare, code } = masked[j];
    const close = bare.indexOf(']', j === start ? bare.indexOf('[') + 1 : 0);
    const span = code.slice(j === start ? bare.indexOf('[') + 1 : 0, close >= 0 ? close : code.length);
    const re = /"([^"]+)"|'([^']+)'/g;
    let m;
    while ((m = re.exec(span))) out.push(m[1] || m[2]);
    if (close >= 0) break;
  }
  return out;
}

// Declared fields carrying the saved-content marker: a 2-space class field whose own line, or the
// contiguous comment block directly above it, holds it.
function contentFields(lines, masked) {
  const out = new Set();
  const keyRe = /^  ([A-Za-z_]\w*):(?!:)/;
  const marked = (j) => CONTENT_MARKER.test(masked[j].comment || '');
  lines.forEach((raw, i) => {
    const m = raw.match(keyRe);
    if (!m) return;
    if (marked(i)) { out.add(m[1]); return; }
    for (let j = i - 1; j >= 0 && isCommentOnly(masked[j]); j--) {
      if (marked(j)) { out.add(m[1]); return; }
    }
  });
  return out;
}

// Every `@field` an assignment writes on a code line: `@a = …`, the compound and existential forms
// (`@a ?= …`, `@a or= …`, `@a += …`), and the targets of a destructuring assignment (`[@a, @b] = …`).
// `==`, `<=`, `>=` and `!=` are comparisons, never writes.
function writtenFields(code) {
  const out = [];
  const re = /@([A-Za-z_]\w*)\s*(?:\?|\|\||&&|or|and|\*\*|[-+*\/%])?=(?!=)/g;
  let m;
  while ((m = re.exec(code))) out.push(m[1]);
  const d = code.match(/\[([^\]]+)\]\s*=(?!=)/);
  if (d) for (const part of d[1].split(',')) { const n = part.trim().match(/^@([A-Za-z_]\w*)$/); if (n) out.push(n[1]); }
  return out;
}

if (!fs.existsSync(SRC)) { console.error('[back-buffer-memos] operational error: no src/ at ' + SRC); process.exit(2); }

const classes = {};   // name -> { file, lines, masked, sup, transients:Set, content:Set, spans }
const problems = [];
for (const p of compiledFiles(ROOTS)) {
  const text = fs.readFileSync(p, 'utf8');
  const lines = text.split('\n');
  const file = sourceName(p, ROOTS);
  const masked = coffeeMask(text, file);
  const spans = methodSpans(lines);
  for (const u of unseenMethodHeaders(lines, masked)) {
    if (u.text.startsWith(BUILDER)) problems.push(rules.fired('UNSEEN_BUILDER_HEADER', `  ${file}:${u.line}  a ${BUILDER} header in a spelling the shared matcher cannot see — this gate would be blind to it: ${u.text}`));
  }
  const cm = lines.map((l) => l.match(/^class\s+(\w+)(?:\s+extends\s+(\w+))?/)).find(Boolean);
  if (cm) {
    classes[cm[1]] = {
      file, lines, masked, spans, sup: cm[2],
      transients: new Set(listDeclaration(lines, masked, '@serializationTransients')),
      content: contentFields(lines, masked),
    };
  }
}

// the chain's merged transients and saved-content declarations
function chainSets(name) {
  const transients = new Set(), content = new Set(), seen = new Set();
  for (let c = name; c && classes[c] && !seen.has(c); c = classes[c].sup) {
    seen.add(c);
    const k = classes[c];
    k.transients.forEach((x) => transients.add(x));
    k.content.forEach((x) => content.add(x));
  }
  return { transients, content };
}

const violations = [];
const keyedBuilders = [];
let builders = 0;
for (const [name, k] of Object.entries(classes)) {
  const methods = new Map();
  for (const s of k.spans) if (!s.static) methods.set(s.name, s);
  const builder = methods.get(BUILDER);
  if (!builder) continue;
  builders++;
  // the builder and every same-file method it reaches through @name references, transitively — except
  // for a KEYED builder (see the header), whose own body is all that is read
  const keyed = k.masked.slice(builder.line + 1, builder.end).some((l) => /\bworld\.cacheForImmutableBackBuffers\b/.test(l.bare));
  if (keyed) keyedBuilders.push(name);
  const reached = [BUILDER], queue = keyed ? [] : [BUILDER];
  while (queue.length) {
    const s = methods.get(queue.shift());
    for (let i = s.line + 1; i < s.end; i++) {
      const re = /@([A-Za-z_]\w*)/g;
      let m;
      const code = k.masked[i].bare;
      while ((m = re.exec(code))) {
        const n = m[1];
        if (n !== 'constructor' && methods.has(n) && !reached.includes(n)) { reached.push(n); queue.push(n); }
      }
    }
  }
  const { transients, content } = chainSets(name);
  for (const mname of reached) {
    const s = methods.get(mname);
    for (let i = s.line + 1; i < s.end; i++) {
      for (const f of writtenFields(k.masked[i].bare)) {
        if (transients.has(f) || content.has(f)) continue;
        violations.push({ name, field: f, at: `${k.file}:${i + 1}`, via: mname, text: k.lines[i].trim() });
      }
    }
  }
}

if (problems.length) {
  console.error('\n[back-buffer-memos] FAIL — shapes this gate refuses to be blind to:');
  for (const p of problems) console.error(p);
}
if (builders === 0) {
  console.error('[back-buffer-memos] operational error: not one ' + BUILDER + ' found under ' + SRC + ' — a run that checked nothing is not a pass.');
  process.exit(2);
}
console.log(`[back-buffer-memos] ${builders} back-buffer builder(s) checked across ${Object.keys(classes).length} classes` +
  (keyedBuilders.length ? `; ${keyedBuilders.length} keyed by world.cacheForImmutableBackBuffers, own body only (${keyedBuilders.sort().join(', ')})` : '') + '.');
if (violations.length) {
  console.error(`\n[back-buffer-memos] FAIL — ${violations.length} field(s) written by a back-buffer builder that ride a save:`);
  for (const v of violations) {
    console.error(rules.fired('MEMO_RIDES_A_SAVE', `  ${v.name}.${v.field}  (${v.at}, in ${v.via}${v.via === BUILDER ? '' : ', reached from ' + BUILDER})`));
    console.error(`    ${v.text}`);
  }
  console.error('\nA field written while the back buffer is built describes that buffer, which is a serialization');
  console.error('transient: keep no memo (ask the raster, or paint unconditionally), declare the field in the');
  console.error("class's @serializationTransients, or — if the field is the saved picture itself — mark its");
  console.error('declaration  # saved-content: <what makes it content>.');
  process.exit(1);
}
if (problems.length) process.exit(1);
console.log('[back-buffer-memos] OK — no back-buffer builder writes a field that rides a save.');
process.exit(0);

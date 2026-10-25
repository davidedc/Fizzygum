#!/usr/bin/env node
'use strict';
// check-back-buffer-memos.js — build gate: A WIDGET KEEPS NO MEMO OF ITS BACK BUFFER.
//
// A widget's back buffer is a Widget serialization transient (`backBuffer`/`backBufferContext` in
// Widget's @serializationTransients): on almost every widget it is a render cache the next paint
// re-derives, so it never rides a save. A field that records what was painted INTO it — "the size I
// last painted my image at", "the background is already laid" — describes that transient, and if the
// field itself rides the save, the restored widget meets a fresh, unpainted raster together with a
// memo claiming the paint is done, and skips it: an image widget that remembers the size it last
// painted at comes back BLACK, a video canvas that remembers its letterbox is laid comes back with the
// letterbox in its paper colour. The cure is to keep no memo — ask the raster (CanvasWdgt hands over a
// NEW raster exactly when there was none or the size changed, which is what SimpleImageWdgt does) or
// paint unconditionally (VideoPlayerCanvasWdgt's letterbox) — and this gate keeps the memo out.
//
// THE RULE. Every `@field` ASSIGNED in a class's back-buffer builder (`_createRefreshOrGetBackBuffer`),
// or in a method of the same file that the builder reaches through `@name` references (transitively),
// must be EITHER
//   - a serialization transient of the class chain: the class's own `@serializationTransients` plus
//     every ancestor's, walked up `extends` — the source-level twin of boot's
//     classStaticListMergedUpTheChain, which reads each class's OWN list and walks on past it, because
//     `extend` copies statics down and a subclass's own list REPLACES that copy at runtime. A mixin's
//     class-side `serializationTransients` key counts at each class that `@augmentWith`s it (the meta
//     system copies a mixin's statics onto its consumers); or
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
// IT READS ALL OF src/, every part, shipped or not — a build that does not ship a part still checks
// its code, which is the point: both raster-cache widgets that drew from a loaded resource live in the
// flag-gated `video-player` part, which no default build carries and so no suite, rig or smoke runs.
// Method grouping is the shared buildSystem/lib/coffee-method-header.js (methodSpans), so a mixin
// member or a class-side key bounds a method exactly as every other gate sees it.
//
// BLIND SPOTS (stated, not silent):
//   - a memo written by a method the builder does NOT reach: an onload/step/event handler that records
//     "already loaded" or "already painted". SimpleImageWdgt's `imageLoaded` is that shape (written in
//     an Image onload closure inside _loadImage); it is a serialization transient by declaration, and
//     this gate would not have noticed if it were not.
//   - methods reached across files (an ancestor's or a mixin's method the builder calls) and dynamic
//     sends (`@[name]()`, a call through another receiver) are not followed; nor is anything a keyed
//     builder reaches (above).
//   - a write through an alias (`self = @`, `that.x = …`) or into a field's contents (`@a.b = …`,
//     `@a[i] = …`) is not a field assignment to this scanner.
//   - a memo in a paint path that is not a back-buffer builder (an appearance's paint, a blit) — those
//     widgets keep no raster to describe, but a future one that did would need its own root here.
// Two shapes it refuses LOUDLY rather than skipping: a back-buffer builder declared inside a MIXIN
// (its transients would be its consumers', which a per-file scan cannot resolve), and a builder header
// written in a spelling the shared matcher cannot see (unseenMethodHeaders) — a gate blind to a method
// reports nothing about it, so blindness is made a failure.
//
// Exit codes: 0 clean · 1 violation · 2 operational (no src/, or not one builder found — a run that
// checked nothing is not a pass).
// Run from the Fizzygum/ repo root (build_it_please.sh does): node ./buildSystem/check-back-buffer-memos.js
// Revert plant: give SimpleImageWdgt's builder a size memo (`@lastPaintedImageSize = @extent()`), or
// delete the `# saved-content:` line above CanvasWdgt.drawnRaster — either fails the gate naming the field.

const fs = require('fs');
const path = require('path');
const { methodSpans, unseenMethodHeaders } = require('./lib/coffee-method-header.js');

const SRC = path.resolve(__dirname, '../src');
const BUILDER = '_createRefreshOrGetBackBuffer';
const CONTENT_MARKER = /#\s*saved-content:\s*\S/;

function walk(dir, acc) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (e.name.endsWith('.coffee')) acc.push(p);
  }
  return acc;
}

// The line with string contents blanked (every column kept) and its comment removed: what is CODE on it.
// Quotes are tracked so a `#` inside a string (`"#{x}"`) is not taken for a comment.
function codeOf(line) {
  let out = '', q = null;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (q) {
      if (ch === '\\') { i++; out += '  '; continue; }
      if (ch === q) { q = null; out += ch; continue; }
      out += ' ';
      continue;
    }
    if (ch === '"' || ch === "'") { q = ch; out += ch; continue; }
    if (ch === '#') break;
    out += ch;
  }
  return out;
}

// The names a class-level list declaration holds — `@serializationTransients: [ … ]` (the key spelled
// with or without the `@`: without is a mixin's class-side form) — read through to its closing bracket.
// Each line's comment goes first, so a quoted word in a comment is not taken for a name: codeOf blanks
// string CONTENTS but keeps every column, so its length marks where the raw line's code ends.
function listDeclaration(lines, key) {
  const head = new RegExp('^  ' + key + ':\\s*\\[');
  const start = lines.findIndex((l) => head.test(l));
  if (start < 0) return [];
  const out = [];
  for (let j = start; j < lines.length; j++) {
    const code = codeOf(lines[j]);
    const close = code.indexOf(']', j === start ? code.indexOf('[') + 1 : 0);
    const span = lines[j].slice(j === start ? code.indexOf('[') + 1 : 0, close >= 0 ? close : code.length);
    const re = /"([^"]+)"|'([^']+)'/g;
    let m;
    while ((m = re.exec(span))) out.push(m[1] || m[2]);
    if (close >= 0) break;
  }
  return out;
}

// Declared fields carrying the saved-content marker: a 2-space class field (or a mixin member key at the
// file's member indent) whose own line, or the contiguous comment block directly above it, holds it.
function contentFields(lines, keyIndent) {
  const out = new Set();
  const keyRe = new RegExp('^' + ' '.repeat(keyIndent) + '([A-Za-z_]\\w*):(?!:)');
  lines.forEach((raw, i) => {
    const m = raw.match(keyRe);
    if (!m) return;
    if (CONTENT_MARKER.test(raw)) { out.add(m[1]); return; }
    for (let j = i - 1; j >= 0 && /^\s*#/.test(lines[j]); j--) {
      if (CONTENT_MARKER.test(lines[j])) { out.add(m[1]); return; }
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

const classes = {};   // name -> { file, lines, sup, transients:Set, content:Set, augments:[] , spans }
const mixins = {};    // name -> { file, transients:Set, content:Set, spans }
const problems = [];
for (const p of walk(SRC, [])) {
  const lines = fs.readFileSync(p, 'utf8').split('\n');
  const file = path.relative(SRC, p);
  const spans = methodSpans(lines);
  for (const u of unseenMethodHeaders(lines)) {
    if (u.text.startsWith(BUILDER)) problems.push(`  ${file}:${u.line}  a ${BUILDER} header in a spelling the shared matcher cannot see — this gate would be blind to it: ${u.text}`);
  }
  const cm = lines.map((l) => l.match(/^class\s+(\w+)(?:\s+extends\s+(\w+))?/)).find(Boolean);
  if (cm) {
    classes[cm[1]] = {
      file, lines, spans, sup: cm[2],
      transients: new Set(listDeclaration(lines, '@serializationTransients')),
      content: contentFields(lines, 2),
      augments: lines.map((l) => l.match(/^  @augmentWith\s+(\w+)/)).filter(Boolean).map((m) => m[1]),
    };
    continue;
  }
  const mm = lines.map((l) => l.match(/^(\w+)\s*=\s*$/)).find(Boolean);
  if (mm && spans.some((s) => s.mixin)) {
    const member = spans.find((s) => s.mixin);
    const indent = lines[member.line].match(/^ */)[0].length;
    mixins[mm[1]] = { file, spans, transients: new Set(listDeclaration(lines, 'serializationTransients')), content: contentFields(lines, indent) };
    for (const s of spans) if (s.mixin && s.name === BUILDER) problems.push(`  ${file}:${s.line + 1}  a ${BUILDER} declared in the mixin ${mm[1]} — its transients are its consumers', which this gate cannot resolve per file`);
  }
}

// the chain's merged transients and saved-content declarations, a class's mixins counted at its own step
function chainSets(name) {
  const transients = new Set(), content = new Set(), seen = new Set();
  for (let c = name; c && classes[c] && !seen.has(c); c = classes[c].sup) {
    seen.add(c);
    const k = classes[c];
    k.transients.forEach((x) => transients.add(x));
    k.content.forEach((x) => content.add(x));
    for (const mx of k.augments) if (mixins[mx]) { mixins[mx].transients.forEach((x) => transients.add(x)); mixins[mx].content.forEach((x) => content.add(x)); }
  }
  return { transients, content };
}

const violations = [];
const keyedBuilders = [];
let builders = 0;
for (const [name, k] of Object.entries(classes)) {
  const methods = new Map();
  for (const s of k.spans) if (!s.static && !s.mixin) methods.set(s.name, s);
  const builder = methods.get(BUILDER);
  if (!builder) continue;
  builders++;
  // the builder and every same-file method it reaches through @name references, transitively — except
  // for a KEYED builder (see the header), whose own body is all that is read
  const keyed = k.lines.slice(builder.line + 1, builder.end).some((l) => /\bworld\.cacheForImmutableBackBuffers\b/.test(codeOf(l)));
  if (keyed) keyedBuilders.push(name);
  const reached = [BUILDER], queue = keyed ? [] : [BUILDER];
  while (queue.length) {
    const s = methods.get(queue.shift());
    for (let i = s.line + 1; i < s.end; i++) {
      const re = /@([A-Za-z_]\w*)/g;
      let m;
      const code = codeOf(k.lines[i]);
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
      for (const f of writtenFields(codeOf(k.lines[i]))) {
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
    console.error(`  ${v.name}.${v.field}  (${v.at}, in ${v.via}${v.via === BUILDER ? '' : ', reached from ' + BUILDER})`);
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

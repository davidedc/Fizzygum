#!/usr/bin/env node
// check-relayout-bounds-first.js — build lint: a `_reLayout` override must APPLY ITS OWN BOUNDS
// before it reads its own geometry to position children. Otherwise the children lay out against the
// PREVIOUS pass's frame and lag one layout cadence on a resize/move (the dpr2 "one-cadence-lag" flake
// fixed in InspectorWdgt 2026-06-16 and then swept across the patch / prompt / app / icon widgets
// 2026-07-02). Mirrors check-thin-wraps.js / check-stinks.js (line scanner; exit 0 clean / 1 violation).
//
// THE RULE. In a `_reLayout: (newBoundsForThisLayout) ->` override, the FIRST read of an own-geometry
// accessor -- @left() @right() @top() @bottom() @width() @height() @position() @topLeft() @topRight()
// @bottomLeft() @bottomRight() @center(), or a bare @bounds read -- must be PRECEDED, in the same method,
// by a SELF-bounds application:
//     @_applyBounds <newBounds>              -- the common form (base Widget re-commits idempotently via super)
//   | @_applyMoveTo … AND @_applyExtent …    -- position + size, the InspectorWdgt form
//   | super / super <newBounds> / Widget::_reLayout.call …   -- base applies bounds, the super-at-TOP form
// The `@_` prefix is what distinguishes a SELF apply from a child apply (`child._applyBounds` does NOT count).
//
// A `_reLayout` that positions children from the `newBoundsForThisLayout` PARAM (never from @-geometry) --
// or that positions no children at all -- has no own-geometry read and passes trivially (the video-player
// widgets, the scroll / vertical-stack containers whose child layout lives in _positionAndResizeChildren,
// the caret which reads its PARENT/TARGET geometry). `@boundingBox()` and `@extent()` are the nil-default
// normalisers, NOT child-positioning reads, so they do not count as own-geometry reads.
//
// EXEMPTION: a `# relayout-bounds-first-exempt: <reason>` marker (non-empty reason) in the comment block
// directly above the `_reLayout` header. The base `Widget::_reLayout` (the applier itself) is skipped.
//
// Reference FIXED shapes: FanoutWdgt._reLayout (@_applyBounds near the top) and InspectorWdgt._reLayout
// (@_applyMoveTo + @_applyExtent near the top). This is the DEF-side companion to that fix arc.

const fs = require('fs');
const path = require('path');
const SRC = path.resolve(__dirname, '../src');

const HEADER = /^  ([A-Za-z_]\w*): (\(.*?\) )?[-=]>/;        // 2-space-indent class method header
const EXEMPT = /#\s*relayout-bounds-first-exempt:\s*\S/;     // marker WITH a non-empty reason
// own-geometry accessor reads that indicate positioning children against MY (about-to-change) frame:
const GEOM = /@(?:left|right|top|bottom|width|height|position|topLeft|topRight|bottomLeft|bottomRight|center)\(\)|@bounds\b(?!\s*=)/;
// SELF-bounds applications -- the `@_` prefix distinguishes self from a `child.apply`:
const APPLY_BOUNDS = /@_applyBounds\b/;
const APPLY_MOVE   = /@_applyMoveTo\b/;
const APPLY_EXTENT = /@_applyExtent\b/;
const SUPER        = /\bsuper\b|Widget::_reLayout\b/;

function walk(dir, acc) {
  if (!fs.existsSync(dir)) return acc;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (e.name.endsWith('.coffee')) acc.push(p);
  }
  return acc;
}
function stripComment(line) { const i = line.indexOf('#'); return i < 0 ? line : line.slice(0, i); }

const violations = [];
let checked = 0, exempt = 0, trivial = 0;
for (const p of walk(SRC, [])) {
  const cls = path.basename(p, '.coffee');
  if (cls === 'Widget') continue;                           // the base _reLayout IS the applier
  const lines = fs.readFileSync(p, 'utf8').split('\n');
  const heads = [];
  lines.forEach((l, i) => { const m = HEADER.exec(l); if (m) heads.push({ name: m[1], i }); });
  for (let k = 0; k < heads.length; k++) {
    if (heads[k].name !== '_reLayout') continue;
    const head = heads[k];
    // EXEMPTION: scan upward through the contiguous comment block directly above the header.
    let marked = false;
    for (let j = head.i - 1; j >= 0 && /^\s*#/.test(lines[j]); j--) {
      if (EXEMPT.test(lines[j])) { marked = true; break; }
    }
    if (marked) { exempt++; continue; }
    const end = k + 1 < heads.length ? heads[k + 1].i : lines.length;
    // Walk the body: has a SELF-apply been seen by the time we hit the first own-geometry read?
    let firstGeom = -1, appliedBeforeGeom = false;
    let sawBounds = false, sawMove = false, sawExtent = false, sawSuper = false;
    for (let j = head.i + 1; j < end; j++) {
      const code = stripComment(lines[j]);
      if (!code.trim()) continue;
      if (GEOM.test(code)) {
        appliedBeforeGeom = sawBounds || sawSuper || (sawMove && sawExtent);
        firstGeom = j;
        break;
      }
      if (APPLY_BOUNDS.test(code)) sawBounds = true;
      if (APPLY_MOVE.test(code)) sawMove = true;
      if (APPLY_EXTENT.test(code)) sawExtent = true;
      if (SUPER.test(code)) sawSuper = true;
    }
    if (firstGeom === -1) { trivial++; continue; }           // no own-geometry positioning -> safe
    if (appliedBeforeGeom) { checked++; continue; }
    violations.push({ cls, file: path.relative(SRC, p), line: head.i + 1, geomLine: firstGeom + 1, geom: lines[firstGeom].trim() });
  }
}

console.log(`[relayout-bounds-first] ${checked} apply-first + ${trivial} param-driven/no-child + ${exempt} exempt _reLayout override(s) checked.`);
if (violations.length) {
  console.error(`\n[relayout-bounds-first] FAIL -- ${violations.length} _reLayout override(s) read own geometry BEFORE applying own bounds (children would lag one cadence on resize):`);
  for (const v of violations) {
    console.error(`  ${v.cls}._reLayout  (${v.file}:${v.line}) -- first own-geometry read at line ${v.geomLine}:  ${v.geom}`);
  }
  console.error('\nFIX: apply own bounds FIRST -- e.g. right after the collapse guard:');
  console.error('       newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout');
  console.error('       @_applyBounds newBoundsForThisLayout');
  console.error('     (see FanoutWdgt._reLayout / InspectorWdgt._reLayout for the fixed shapes; the trailing super re-commits idempotently).');
  console.error('Or add  # relayout-bounds-first-exempt: <reason>  directly above the _reLayout header.');
  process.exit(1);
}
console.log('[relayout-bounds-first] OK -- every _reLayout applies its own bounds before reading its own geometry.');
process.exit(0);

#!/usr/bin/env node
// check-plane-discipline.js — build lint: the three statically-checkable rules of the
// paint-time scroll model (stored offset + pinned plane + two-arm mapped walks; living
// truth: docs/architecture/viewports-and-planes.md). Exit 0 clean / 1 violation.
//
// A. THE OFFSET FUNNEL (hard zero). `scrollOffsetX/Y` are MAPPING state: a write must break
//    the geometryVersion-keyed caches and damage the viewport, which only the
//    `_writeScrollOffset` funnel does (ViewportWdgt — see its header). A bare field
//    assignment anywhere else paints right and hit-tests WRONG (the measured
//    hit-invisible-scrolled-row class), so it fails the build outright. Prototype
//    defaults (`scrollOffsetX: 0`) are declarations, not writes.
//
// B. CROSS-PLANE POSITIONAL MIXING (count ratchet, the check-stinks idiom). POSITIONAL
//    geometry (position/left/top/center/bounds/… — plane-RELATIVE, unlike width/height/
//    extent which are plane-invariant) of two DISTINCT receivers combined on one line,
//    with no mapping call on the line, is sound only when both receivers share a plane —
//    and silently wrong otherwise, dormant at scroll offset 0 / identity transform (the
//    class every hard bug of the paint-time scroll arc belonged to). Same-plane-by-
//    construction sites are legitimate and EXPECTED (a container laying out its own
//    children), so this is a BASELINE, not a ban: a count above it fails the build and
//    prints the new lines — classify each (same-plane ⇒ raise the baseline with a reason;
//    cross-plane ⇒ map through localPointToScreen / screenPointToMyPlane / screenBounds).
//    A count BELOW baseline also fails, loudly asking to ratchet down — that is the win
//    being locked in. Known blind spots (by design — line-level only): a positional value
//    stored in one method and consumed in another plane elsewhere; a position forwarded
//    through an opts key; a bare variable whose provenance is another widget's geometry.
//
// C. THE ESCALATION BOUNDARY (hard zero). `escalateEvent` forwards pointer-handler args
//    VERBATIM up the parent chain, so a handler on a scroll-translation PROVIDER (or a
//    subclass) can receive a `pos` still expressed in a descendant plane — offset-pixels
//    away from its own (the measured stationary-click-slams-to-clamp defect). Rule (the
//    viewports-and-planes.md input rule, given teeth): a positional pointer handler
//    defined on a class that provides `scrollTranslationOfChild` (transitively, via
//    extends) must either not read its pos parameter or re-derive via
//    `screenPointToMyPlane` in the same body. `wheel` is exempt (deltas, not positions).
//    Exemption marker for a future deliberate consumer:
//    `# escalated-pos-sanctioned: <reason>` directly above the handler header.

const fs = require('fs');
const path = require('path');
const SRC = path.resolve(__dirname, '../src');
const { METHOD_HEADER: HEADER } = require('./lib/coffee-method-header');

// ---- baseline for section B (the check-stinks idiom: exact count, move it consciously) ----
const CROSS_PLANE_MIX_BASELINE = 35;

const POSITIONAL = 'position|left|right|top|bottom|center|boundingBox|fullBounds|topLeft|topRight|bottomLeft|bottomRight|origin|corner';
const CALL_RE = new RegExp('(@?[A-Za-z_$][A-Za-z0-9_$]*)((?:\\.[A-Za-z_$][A-Za-z0-9_$]*)*?)\\.(' + POSITIONAL + ')\\s*\\(', 'g');
const BOUNDS_RE = new RegExp('(@?[A-Za-z_$][A-Za-z0-9_$]*)((?:\\.[A-Za-z_$][A-Za-z0-9_$]*)*?)\\.(bounds)\\b(?!\\s*=[^=])', 'g');
const BARE_RE = new RegExp('(?<![A-Za-z0-9_$.])@(' + POSITIONAL + ')\\s*\\(', 'g');
const BARE_BOUNDS_RE = /(?<![A-Za-z0-9_$.])@bounds\b(?!\s*=[^=])/;
const MAPPED_RE = /screenPointToMyPlane|localPointToScreen|mapRectToScreen|screenBounds|scrollTranslationOfChild|_scrollTranslation|scrollOffset/;
const NON_WIDGET_ROOTS = new Set(['Math', 'Rectangle', 'Point', 'window', 'JSON', 'Object']);

const POS_HANDLER_NAMES = new Set([
  'pressBegan', 'pressEnded',
  'activated', 'mouseClickRight', 'doubleActivated', 'tripleActivated',
  'mouseMove', 'nonFloatDragging',
]);
const ESCALATED_EXEMPT = /#\s*escalated-pos-sanctioned:\s*\S/;

function walk(dir, acc) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (e.name.endsWith('.coffee')) acc.push(p);
  }
  return acc;
}
function stripComment(line) { const i = line.indexOf('#'); return i < 0 ? line : line.slice(0, i); }

const files = walk(SRC, []);
const funnelViolations = [];
const mixLines = [];
const providerDefiners = new Set();
const classParent = new Map();   // class -> extends parent
const classFile = new Map();     // class -> file path

// pass 1: scan lines; collect class graph + provider definers
for (const p of files) {
  const rel = path.relative(SRC, p);
  const lines = fs.readFileSync(p, 'utf8').split('\n');
  let inMethod = '';
  lines.forEach((raw, i) => {
    const cls = raw.match(/^class\s+([A-Za-z0-9_$]+)(?:\s+extends\s+([A-Za-z0-9_$]+))?/);
    if (cls) { classFile.set(cls[1], p); if (cls[2]) classParent.set(cls[1], cls[2]); }
    const mSig = raw.match(HEADER);
    if (mSig) inMethod = mSig[1];
    if (/^  scrollTranslationOfChild\s*:/.test(raw)) {
      // attribute to the class this file declares (one class per file)
      for (const [c, f] of classFile) if (f === p) providerDefiners.add(c);
    }
    const line = stripComment(raw);
    if (!line.trim()) return;

    // A — bare offset writes
    if (/(?:@|\.)scrollOffset[XY]\s*=[^=]/.test(line) && inMethod !== '_writeScrollOffset'
        && !/^\s*scrollOffset[XY]\s*:/.test(raw))
      funnelViolations.push(`${rel}:${i + 1}: [in ${inMethod}] ${raw.trim()}`);

    // B — two-receiver positional mixing
    const roots = new Set();
    for (const re of [CALL_RE, BOUNDS_RE]) {
      re.lastIndex = 0;
      let m;
      while ((m = re.exec(line)) !== null) {
        if (NON_WIDGET_ROOTS.has(m[1])) continue;
        // '@bounds' as a chain root is the widget's OWN box (@bounds.left() === @left()) —
        // fold it into '@' so an accessor body is one receiver, not a phantom mix
        roots.add(m[1] === '@bounds' ? '@' : m[1]);
      }
    }
    BARE_RE.lastIndex = 0;
    if (BARE_RE.test(line)) roots.add('@');
    if (BARE_BOUNDS_RE.test(line)) roots.add('@');
    if (roots.size >= 2 && !MAPPED_RE.test(line))
      mixLines.push(`${rel}:${i + 1}: [${[...roots].join(' vs ')}] ${raw.trim()}`);
  });
}

// C — pos-reading handlers on provider classes (transitive subclasses included)
function providesTranslation(cls) {
  let c = cls, hops = 0;
  while (c && hops++ < 50) { if (providerDefiners.has(c)) return true; c = classParent.get(c); }
  return false;
}
const escalationViolations = [];
for (const [cls, p] of classFile) {
  if (!providesTranslation(cls)) continue;
  const lines = fs.readFileSync(p, 'utf8').split('\n');
  for (let i = 0; i < lines.length; i++) {
    const mSig = lines[i].match(HEADER);
    if (!mSig || !POS_HANDLER_NAMES.has(mSig[1])) continue;
    const params = (lines[i].match(/\(([^)]*)\)/) || [])[1];
    if (!params) continue;                               // zero-param handler: nothing escalated to misread
    const first = params.split(',')[0].trim().replace(/=.*$/, '').trim();
    if (!first || first.startsWith('ignored')) continue;
    // body span: until the next 2-space method header
    let body = '', exempt = false;
    for (let k = i - 1; k >= 0 && /^\s*#/.test(lines[k]); k--) if (ESCALATED_EXEMPT.test(lines[k])) exempt = true;
    for (let j = i + 1; j < lines.length && !HEADER.test(lines[j]); j++) body += stripComment(lines[j]) + '\n';
    const readsPos = new RegExp('(?<![A-Za-z0-9_$])' + first.replace('$', '\\$') + '(?![A-Za-z0-9_$])').test(body);
    const reDerives = /screenPointToMyPlane/.test(body);
    const onlyEscalates = new RegExp('escalateEvent\\s+["\']' + mSig[1]).test(body);
    if (readsPos && !reDerives && !onlyEscalates && !exempt)
      escalationViolations.push(`${path.relative(SRC, p)}:${i + 1}: ${cls}.${mSig[1]} reads '${first}' without re-deriving via screenPointToMyPlane`);
  }
}

// ---- report ----
let failed = false;
if (funnelViolations.length) {
  failed = true;
  console.error(`[plane-discipline A] FAIL — ${funnelViolations.length} bare scrollOffset write(s) outside _writeScrollOffset:`);
  funnelViolations.forEach((l) => console.error('    ' + l));
} else console.log('[plane-discipline A] offset funnel: 0 bare writes -- OK');

if (mixLines.length !== CROSS_PLANE_MIX_BASELINE) {
  failed = true;
  console.error(`[plane-discipline B] FAIL — cross-plane positional-mix count ${mixLines.length} != baseline ${CROSS_PLANE_MIX_BASELINE}.`);
  if (mixLines.length > CROSS_PLANE_MIX_BASELINE)
    console.error('    New mixed-positional line(s) — classify each: same-plane-by-construction => raise the baseline with a one-line reason in the commit; cross-plane => map it. Current lines:');
  else
    console.error('    Count DROPPED — good: lower the baseline to lock it in. Current lines:');
  mixLines.forEach((l) => console.error('    ' + l));
} else console.log(`[plane-discipline B] cross-plane positional mixing: ${mixLines.length} (baseline ${CROSS_PLANE_MIX_BASELINE}) -- OK`);

if (escalationViolations.length) {
  failed = true;
  console.error(`[plane-discipline C] FAIL — ${escalationViolations.length} pos-reading handler(s) on scroll-translation providers:`);
  escalationViolations.forEach((l) => console.error('    ' + l));
} else console.log(`[plane-discipline C] escalation boundary: 0 unguarded pos-reading handlers on ${providerDefiners.size} provider class(es) + subclasses -- OK`);

process.exit(failed ? 1 : 0);

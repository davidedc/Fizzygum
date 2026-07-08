#!/usr/bin/env node
'use strict';
// Sum SELF time over named function groups for the SWCanvas bucket.
const fs = require('fs');
const prefix = process.argv[2];
const profile = JSON.parse(fs.readFileSync(prefix + '.cpuprofile', 'utf8'));
const segments = JSON.parse(fs.readFileSync(process.argv[3], 'utf8'));

const GROUPS = [
  ['drawImage-pipeline', /^(drawImage|_drawImageInternal|_toImageLike)$/],
  ['clip-mask-build', /^(fillPolygonsToClipMask|_fillClipMaskSpans|BitBuffer|_setBit|clone|intersectWith|and$)/],
  ['clip-mask-read', /^(_getBit|isPixelClipped|getPixel)$/],
  ['polygon-fill+span', /^(_fillPixelSpan|_fillPolygonsDirect|fill_AA_Alpha|fill_AA_Opaq|_fillScanline|_findPolygonIntersections|_fillSpans|fillPolygons|_fillInternal|_evaluatePaintSource|_fillAxisAlignedRect)$/],
  ['blend+color', /^(blendPixel|_blendPixel|Color|get [rgba]|withGlobalAlpha|premultiply|unpremultiply)$/],
  ['stroke-gen', /^(generateStrokePolygons|_generateSegmentStroke|_addJoin|_addCap|flattenPath|_flattenSegment)$/],
  ['text', /^(fillText|_drawGlyph|addFontIDs|measureText|_blitGlyph)$/],
  ['save-restore', /^(save|restore|_createSnapshot|_applySnapshot)$/],
  ['compositing-wide', /^(_performCanvasWideCompositing|SourceMask)$/],
  ['clearRect', /^(_clearRectDirect|clearRect)$/],
  ['transform', /^(transformPoint|invert|Transform2D|Point)$/],
];

function segmentFor(line) {
  for (const s of segments) if (line >= s.startLine && line <= s.endLine) return s.name;
  return '?';
}
const selfUs = new Map();
const samples = profile.samples || [], deltas = profile.timeDeltas || [];
for (let i = 0; i < samples.length; i++) { const dt = deltas[i] > 0 ? deltas[i] : 0; selfUs.set(samples[i], (selfUs.get(samples[i]) || 0) + dt); }
let busyUs = 0, swUs = 0;
const groupUs = new Map(GROUPS.map((g) => [g[0], 0]));
let swOther = new Map();
for (const n of profile.nodes) {
  const us = selfUs.get(n.id) || 0;
  if (!us) continue;
  const fn = n.callFrame.functionName;
  if (fn !== '(idle)' && fn !== '(program)' && fn !== '(root)') busyUs += us;
  const inSW = n.callFrame.url && n.callFrame.url.includes('profile-boot.js') && segmentFor(n.callFrame.lineNumber + 1) === 'SWCanvas';
  if (!inSW) continue;
  swUs += us;
  let hit = false;
  for (const [name, re] of GROUPS) if (re.test(fn)) { groupUs.set(name, groupUs.get(name) + us); hit = true; break; }
  if (!hit) swOther.set(fn, (swOther.get(fn) || 0) + us);
}
const ms = (us) => (us / 1000).toFixed(0);
console.log('busy ' + ms(busyUs) + ' ms; SWCanvas ' + ms(swUs) + ' ms (' + ((100 * swUs) / busyUs).toFixed(1) + '% busy)');
for (const [name, us] of [...groupUs.entries()].sort((a, b) => b[1] - a[1])) {
  console.log('  ' + ((100 * us) / busyUs).toFixed(1).padStart(5) + '%busy  ' + ms(us).padStart(7) + ' ms  ' + name);
}
console.log('  -- ungrouped SW top:');
for (const [fn, us] of [...swOther.entries()].sort((a, b) => b[1] - a[1]).slice(0, 12)) {
  console.log('  ' + ((100 * us) / busyUs).toFixed(1).padStart(5) + '%busy  ' + ms(us).padStart(7) + ' ms  ' + fn);
}

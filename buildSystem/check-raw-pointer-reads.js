#!/usr/bin/env node
// check-raw-pointer-reads.js — build lint: a POINTER-EVENT HANDLER body must not consume the raw
// screen-plane pointer. Mirrors check-relayout-bounds-first.js (line scanner; exit 0 clean / 1 violation).
//
// THE RULE. Since affine Phase 4A the dispatcher hands every pointer handler the pointer position
// ALREADY inverse-mapped into the receiver's own plane (ActivePointerWdgt._pointerPositionInPlaneOf,
// forwarded verbatim by escalateEvent within one island plane). `world.hand.position()` is the raw
// SCREEN-plane point: mixing it with plane-local geometry (@position()/bounds) works for aligned
// widgets — off any island the mapped point IS the raw point — and silently breaks for tilted ones
// (the 2026-07-17 spreadsheet tilted-selection bug; the invisible-until-tilted bug class this gate
// exists to kill). So inside a handler body, `world.hand.position()` may appear ONLY mapped at the
// read site — `screenPointToMyPlane` on the SAME line (the per-frame sampling idiom: a drag-scroll
// step legitimately samples the hand each frame, but must map each sample — ScrollPanelWdgt). A
// handler that needs the pointer as a position should otherwise consume its `pos` PARAMETER.
//
// SCOPE. Method bodies (2-space-indent headers, span until the next header) whose names are the
// dispatched pointer-handler names below — closures defined inside them (a drag-scroll @step, a
// _settleLayoutsAfter thunk) are inside the span and covered. HELPERS a handler calls are NOT
// scanned (a heuristic tripwire, not a proof): the known deliberate raw-screen consumer
// (HandleWdgt._pointerAngleToTargetAnchorDegrees — the rotate handle measures an angle in SCREEN
// space by design, see its comment) lives in such a helper. ActivePointerWdgt.coffee is skipped
// wholesale (it IS the hand/dispatcher). Screen-space PLACEMENT of new top-level widgets
// (open-a-window-at-the-hand) lives outside handler-named methods and is untouched.
//
// EXEMPTION: a `# raw-screen-pointer-sanctioned: <reason>` marker (non-empty reason) in the comment
// block directly above the handler header. No current site needs it.

const fs = require('fs');
const path = require('path');
const SRC = path.resolve(__dirname, '../src');

const HEADER = /^  ([A-Za-z_]\w*): (\(.*?\) )?[-=]>/;        // 2-space-indent class method header
const EXEMPT = /#\s*raw-screen-pointer-sanctioned:\s*\S/;    // marker WITH a non-empty reason
const RAW_READ = /world\.hand\.position\(\)/;
const MAPPED = /screenPointToMyPlane/;
const HANDLER_NAMES = new Set([
  'mouseDownLeft', 'mouseDownRight',
  'mouseUpLeft', 'mouseUpRight',
  'mouseClickLeft', 'mouseClickRight',
  'mouseDoubleClick', 'mouseTripleClick',
  'mouseMove',
  'mouseEnter', 'mouseLeave', 'mouseEnterfloatDragging', 'mouseLeavefloatDragging',
  'nonFloatDragging', 'endOfNonFloatDrag',
  'wheel',
]);

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
let checked = 0, exempt = 0;
for (const p of walk(SRC, [])) {
  const cls = path.basename(p, '.coffee');
  if (cls === 'ActivePointerWdgt') continue;                 // the hand/dispatcher itself
  const lines = fs.readFileSync(p, 'utf8').split('\n');
  let inHandler = false, handlerName = null, handlerExempt = false;
  let commentBlockHasExempt = false;
  for (let n = 0; n < lines.length; n++) {
    const line = lines[n];
    const head = line.match(HEADER);
    if (head) {
      inHandler = HANDLER_NAMES.has(head[1]);
      handlerName = head[1];
      handlerExempt = commentBlockHasExempt;
      if (inHandler) { checked++; if (handlerExempt) exempt++; }
      commentBlockHasExempt = false;
      continue;
    }
    // track the comment block directly above the NEXT header
    if (/^\s*#/.test(line)) { if (EXEMPT.test(line)) commentBlockHasExempt = true; }
    else if (line.trim() !== '' && !HEADER.test(line) && /^\S/.test(line)) { commentBlockHasExempt = false; }
    else if (line.trim() === '') { /* blank keeps the block */ }
    if (!inHandler || handlerExempt) continue;
    const code = stripComment(line);
    if (RAW_READ.test(code) && !MAPPED.test(code)) {
      const rel = path.relative(path.resolve(__dirname, '..'), p);
      violations.push(`[raw-pointer] ${cls}.${handlerName} reads world.hand.position() unmapped — ${rel}:${n + 1}\n`
        + `    consume the plane-mapped \`pos\` parameter, or map the sample at the read site:\n`
        + `    @screenPointToMyPlane world.hand.position()  (off-island this is the same point;\n`
        + `    tilted it is the difference between the right cell and the wrong one)`);
    }
  }
}

if (violations.length) {
  console.error(`raw-pointer-reads gate: ${violations.length} violation(s) in ${checked} handler bodies scanned:`);
  for (const v of violations) console.error('  ' + v);
  process.exit(1);
}
console.log(`  raw-pointer-reads gate OK — ${checked} pointer-handler bodies scanned, ${exempt} exempt, 0 raw reads.`);
process.exit(0);

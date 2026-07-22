#!/usr/bin/env node
// check-invalidation-receivers.js — build lint: invalidation is SELF-invalidation.
// Mirrors check-raw-pointer-reads.js (line scanner; exit 0 clean / 1 violation).
//
// THE RULE (docs/architecture/widget-citizenship.md, contract point 2). A widget invalidates
// only itself: `@_changed()` / `@_fullChanged()` — PRIVATE since the 2026-07-22 phase-2
// rename (invalidation is not exposed as API anywhere; the only external callers are the
// test ORACLES, sanctioned by name). The paint executor `_updateBroken` (the world's
// once-per-cycle broken-rect flush) is in the same private family and gated here too — only
// the world's own cycle runs it; the harness paint audit is its one sanctioned outside caller.
// If A's action affects B's pixels, B marks itself changed inside
// the method A invoked on it — A never reaches over with `B._changed()`. The pattern below
// also matches the pre-rename public spellings so a legacy-name call cannot slip back in.
// The 2026-07-22 audit found the reaching-over form was almost always either
// (a) REDUNDANT — the structural dispatcher (`_addNoSettle`, `drop`) already fullChanges the
// widget being moved, and broken rects are fleshed out at end-of-cycle flush from
// last-painted + current bounds, so one mark per cycle covers every same-cycle mutation — or
// (b) a missing receiver-side self-invalidation (e.g. `getContextForPainting` now marks its
// own canvas).
//
// ALLOWED RECEIVER: `@` (self) only — a self-call is dotless and never matches here. The
// shared singletons are NOT exempt (since the 2026-07-22 phase-1 internalization): a widget
// that needs the world/caret/hand to repaint calls an intent-named PUBLIC method on it
// (WorldWdgt.noteWallpaperChanged / resetImmutableBackBuffersCache, CaretWdgt.noteTextChanged,
// ActivePointerWdgt.noteCarriedWidgetChanged) and the singleton invalidates ITSELF inside it.
// There is deliberately NO general-purpose public repaint verb (owner decision 2026-07-22 —
// the old "restore display" menu entry was removed with it).
//
// EXEMPTION: a `# cross-invalidation-sanctioned: <reason>` marker (non-empty reason) on the
// SAME line or the comment line(s) directly above. Sanctioned today: the structural-move
// dispatchers (Widget._addNoSettle, Widget.bringToForeground,
// Widget.fullChangedIncludingShadowOwner, ActivePointerWdgt.drop), the world's
// selection-overlay reconciler (pull model — no target-side seam), FileLoading's deferred
// async-asset repaint, and the own-sub-part sites where a NoSettle mutation tier is
// deliberately non-invalidating (NumberPromptWdgt, MenuItemWdgt). Adding a NEW cross-widget
// invalidation requires either moving the mark into the receiver's mutation method (the
// conforming shape) or a marker with a reason that survives review.

const fs = require('fs');
const path = require('path');
const SRC = path.resolve(__dirname, '../src');

const CALL = /\.(_?changed|_?fullChanged|_?updateBroken)\??\(/g;
const EXEMPT = /#\s*cross-invalidation-sanctioned:\s*\S/;
const RECEIVER_CHARS = /[\w$@?.()\[\]]/;
const ALLOWED = new Set([]);   // no receiver is exempt — see the header

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
function receiverBefore(code, dotIndex) {
  let start = dotIndex;
  while (start > 0 && RECEIVER_CHARS.test(code[start - 1])) start--;
  return code.slice(start, dotIndex).replace(/\?+$/, '');
}

const violations = [];
let sites = 0, allowed = 0, sanctioned = 0;
for (const p of walk(SRC, [])) {
  const rel = path.relative(path.resolve(__dirname, '..'), p);
  const lines = fs.readFileSync(p, 'utf8').split('\n');
  let pendingSanction = false;                       // set by a marker comment line, consumed by the next code line
  for (let n = 0; n < lines.length; n++) {
    const line = lines[n];
    if (/^\s*#/.test(line)) {                        // pure comment line: may arm the sanction for the code below
      if (EXEMPT.test(line)) pendingSanction = true;
      continue;
    }
    const lineSanctioned = pendingSanction || EXEMPT.test(line);
    if (line.trim() !== '') pendingSanction = false; // any code line consumes the pending marker; blanks keep it
    const code = stripComment(line);
    let m;
    CALL.lastIndex = 0;
    while ((m = CALL.exec(code)) !== null) {
      sites++;
      const recv = receiverBefore(code, m.index);
      if (ALLOWED.has(recv)) { allowed++; continue; }
      if (lineSanctioned) { sanctioned++; continue; }
      violations.push(`[invalidation] ${rel}:${n + 1} — \`${recv || '<?>'}.${m[1]}()\` invalidates another widget\n`
        + `    a widget invalidates only itself (widget-citizenship point 2): make the receiver mark\n`
        + `    itself changed inside the method you invoke on it — or, for genuine dispatcher plumbing,\n`
        + `    add \`# cross-invalidation-sanctioned: <reason>\` on or directly above this line`);
    }
  }
}

if (violations.length) {
  console.error(`invalidation-receivers gate: ${violations.length} violation(s) among ${sites} non-self invalidation call sites:`);
  for (const v of violations) console.error('  ' + v);
  process.exit(1);
}
console.log(`  invalidation-receivers gate OK — ${sites} dotted changed()/fullChanged() sites: ${allowed} singleton-allowed, ${sanctioned} sanctioned, 0 violations.`);
process.exit(0);

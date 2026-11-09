#!/usr/bin/env node
// check-invalidation-receivers.js — build lint: invalidation is SELF-invalidation.
// Mirrors check-raw-pointer-reads.js (line scanner; exit 0 clean / 1 violation).
//
// THE RULE (docs/architecture/widget-citizenship.md, contract point 2). A widget invalidates
// only itself: `@_changed()` / `@_fullChanged()` — PRIVATE since the 2026-07-22 phase-2
// rename (invalidation is not exposed as API anywhere; the only external callers are the
// test ORACLES, each carrying the EXEMPTION marker below). The paint executor `_repaintDamagedRects` (the world's
// once-per-cycle damage-rect flush) is in the same private family and gated here too — only
// the world's own cycle runs it, and an outside caller carries the EXEMPTION marker below (the
// harness's paint-truthfulness audit, the oracle that forces the ground-truth repaint).
// If A's action affects B's pixels, B marks itself changed inside
// the method A invoked on it — A never reaches over with `B._changed()`. The pattern below
// also matches the pre-rename public spellings so a legacy-name call cannot slip back in.
// The 2026-07-22 audit found the reaching-over form was almost always either
// (a) REDUNDANT — the structural dispatcher (`_addNoSettle`, `drop`) already fullChanges the
// widget being moved, and damage rects are fleshed out at end-of-cycle flush from
// last-painted + current bounds, so one mark per cycle covers every same-cycle mutation — or
// (b) a missing receiver-side self-invalidation (e.g. `getContextForPainting` now marks its
// own canvas).
//
// ALLOWED RECEIVER: `@` (self) only — a self-call is dotless and never matches here. The
// shared singletons are NOT exempt (since the 2026-07-22 phase-1 internalization): a widget
// that needs the world/caret/hand to repaint calls an intent-named PUBLIC method on it
// (WorldWdgt.noteWallpaperChanged / noteWidgetCopied / resetImmutableBackBuffersCache,
// CaretWdgt.noteTextChanged, ActivePointerWdgt.noteCarriedWidgetChanged) and the singleton
// invalidates ITSELF / mutates ITS OWN bookkeeping inside it.
// There is deliberately NO general-purpose public repaint verb (owner decision 2026-07-22 —
// the old "restore display" menu entry was removed with it).
//
// Each file is read through lib/coffee-mask.js: a call is matched on its bare code (comments and literal contents
// blanked), so neither a comment nor a `#` or quote inside a string or regex can hide the call after it.
//
// EXEMPTION: a `# cross-invalidation-sanctioned: <reason>` marker (non-empty reason) in a comment on the
// SAME line or the comment line(s) directly above. Sanctioned today: the structural-move
// dispatchers (Widget._addNoSettle, Widget.bringToForeground,
// Widget._fullChangedIncludingShadowOwner, ActivePointerWdgt.drop), the world's
// selection-overlay reconciler (pull model — no target-side seam), FileLoading's deferred
// async-asset repaint, and the own-sub-part sites where a NoSettle mutation tier is
// deliberately non-invalidating (NumberPromptWdgt, MenuItemWdgt). Adding a NEW cross-widget
// invalidation requires either moving the mark into the receiver's mutation method (the
// conforming shape) or a marker with a reason that survives review.
//
// It reads the compiled sources (lib/source-files.js compiledFiles: src/ and the tests repo's harness); the verbs it
// gates are read from src's Widget and WorldWdgt.
//
// Run from the Fizzygum/ repo root (build_it_please.sh does): node ./buildSystem/check-invalidation-receivers.js
// [--src=DIR] [--tests-repo=DIR] — the rails check another src tree or tests repo (a copy carrying a plant). Exit 0
// clean / 1 violation / 2 operational. That both rules BITE, and that every sanctioned form passes, is proven on every
// build by check-invalidation-receivers-selftest.js.

const fs = require('fs');
const path = require('path');
const { rejectUnknownArgs, rejectPositionalArgs } = require('./lib/cli-args');
const { compiledFiles, sourceRoots, sourceName, SOURCE_RAILS } = require('./lib/source-files');
const rules = require('./lib/gate-rules').forGate(__filename);

const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, [...SOURCE_RAILS], 'invalidation-receivers');
rejectPositionalArgs(ARGV, 'invalidation-receivers', 'a src tree is named with --src=DIR');
const ROOTS = sourceRoots(ARGV, 'invalidation-receivers');
const SRC = ROOTS.src;

// WHAT IS GATED, READ FROM THE SOURCE rather than spelled here: the repaint verbs Widget defines
// (lib/repaint-verbs.js — `_changed`, `_fullChanged`, the `_fullChanged…` variants), each also in its
// underscore-less legacy spelling so a pre-rename call cannot slip back in, plus the world's paint
// executor, whose name is ASSERTED: a name WorldWdgt.coffee no longer defines fails the gate as stale.
// A hand-spelled pattern here kept the executor's pre-rename name for months, so it was checked by
// nothing, and could not match `_fullChangedIncludingShadowOwner` at all.
const { repaintVerbs } = require('./lib/repaint-verbs');
const PAINT_EXECUTOR = '_repaintDamagedRects';
let VERBS;
try { VERBS = repaintVerbs(SRC); } catch (e) { console.error('invalidation-receivers gate: ' + e.message); process.exit(2); }
if (!new RegExp('^  ' + PAINT_EXECUTOR + '\\s*:', 'm').test(fs.readFileSync(path.join(SRC, 'WorldWdgt.coffee'), 'utf8'))) {
  console.error(rules.fired('STALE_PAINT_EXECUTOR', `invalidation-receivers gate: STALE — WorldWdgt.coffee defines no ${PAINT_EXECUTOR}, the paint executor this gate keeps private; rename PAINT_EXECUTOR to match`));
  process.exit(1);
}
const GATED = VERBS.concat(VERBS.map((v) => v.replace(/^_/, '')), [PAINT_EXECUTOR])
  .sort((a, b) => b.length - a.length);              // longest first, so an alternation reads the longest name
const CALL = new RegExp('\\.(' + GATED.join('|') + ')\\??\\(', 'g');
const EXEMPT = /#\s*cross-invalidation-sanctioned:\s*\S/;
const RECEIVER_CHARS = /[\w$@?.()\[\]]/;
const ALLOWED = new Set([]);   // no receiver is exempt — see the header
const SELF = new Set(['this', '@']);   // `this._changed()` is the self-call `@_changed()` spelled out: not a site at all

const { coffeeMask, isCommentOnly } = require('./lib/coffee-mask');
function receiverBefore(code, dotIndex) {
  let start = dotIndex;
  while (start > 0 && RECEIVER_CHARS.test(code[start - 1])) start--;
  return code.slice(start, dotIndex).replace(/\?+$/, '');
}

const violations = [];
let sites = 0, allowed = 0, sanctioned = 0;
for (const p of compiledFiles(ROOTS)) {
  const rel = sourceName(p, ROOTS, 'src/');
  const masked = coffeeMask(fs.readFileSync(p, 'utf8'), rel);
  let pendingSanction = false;                       // set by a marker comment line, consumed by the next code line
  for (let n = 0; n < masked.length; n++) {
    const line = masked[n];
    const marked = EXEMPT.test(line.comment || '');
    if (isCommentOnly(line)) {                       // pure comment line: may arm the sanction for the code below
      if (marked) pendingSanction = true;
      continue;
    }
    const lineSanctioned = pendingSanction || marked;
    if (line.code.trim() !== '') pendingSanction = false; // any code line consumes the pending marker; blanks keep it
    const code = line.bare;
    let m;
    CALL.lastIndex = 0;
    while ((m = CALL.exec(code)) !== null) {
      sites++;
      const recv = receiverBefore(code, m.index);
      if (SELF.has(recv)) { sites--; continue; }
      if (ALLOWED.has(recv)) { allowed++; continue; }
      if (lineSanctioned) { sanctioned++; continue; }
      violations.push(rules.fired('CROSS_INVALIDATION', `[invalidation] ${rel}:${n + 1} — \`${recv || '<?>'}.${m[1]}()\` invalidates another widget\n`
        + `    a widget invalidates only itself (widget-citizenship point 2): make the receiver mark\n`
        + `    itself changed inside the method you invoke on it — or, for genuine dispatcher plumbing,\n`
        + `    add \`# cross-invalidation-sanctioned: <reason>\` on or directly above this line`));
    }
  }
}

if (violations.length) {
  console.error(`invalidation-receivers gate: ${violations.length} violation(s) among ${sites} non-self invalidation call sites:`);
  for (const v of violations) console.error('  ' + v);
  process.exit(1);
}
console.log(`  invalidation-receivers gate OK — ${sites} dotted [${GATED.join(', ')}] sites: ${allowed} singleton-allowed, ${sanctioned} sanctioned, 0 violations.`);
process.exit(0);

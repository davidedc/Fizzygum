#!/usr/bin/env node
// check-relayout-repaints.js — build lint for INVARIANT [INV-1] (2026-07 layout-regressions arc,
// docs/layout-regressions-2026-07-icons-plots-editghosts-plan.md §2). Static sibling to the runtime
// paint-truthfulness capstone (Fizzygum-tests scripts/run-paint-audit.js). Mirrors
// check-relayout-bounds-first.js (line scanner; exit 0 clean / 1 violation).
//
// THE RULE ([INV-1]). A `_reLayoutSelf` that opens a change-tracking-suppression frame with
// `world.disableTrackChanges()` MUST issue a covering `@fullChanged()` (or `world.fullChanged()`)
// AFTER its LAST `world.maybeEnableTrackChanges()` — i.e. once the outermost tracking frame has
// actually re-armed. Inside a still-open (nested) suppression frame `fullChanged` is a no-op DROPPED
// by design, so a repaint issued before the matching `maybeEnableTrackChanges` is silently lost. When
// a `_reLayoutSelf` applies geometry raw (`@_applyMoveTo`/`@_applyExtent`, whose public-setter
// equivalents used to mark the moved region), dropping that covering repaint leaves a stale / "ghost"
// region on the canvas — exactly the D2 edit/view-toggle ghosts fixed 2026-07 in the five
// StretchableEditable-family `_reLayoutSelf`s (Fizzygum a88a1673). In-tree precedent for the FIXED
// shape: HorizontalMenuPanelWdgt._reLayoutSelf, and the five F2 bodies (StretchableEditableWdgt /
// SimpleSlideWdgt / DashboardsWdgt / PatchProgrammingWdgt / ReconfigurablePaintWdgt).
//
// SCOPE — `_reLayoutSelf` ONLY (the layout method that OWNS its covering repaint). A `_reLayout`
// *orchestrator* override, by contrast, ends by delegating to `super` (base `Widget::_reLayout`,
// which re-applies its own bounds and positions stack/corner children) — a structurally different
// tail — so this line scanner deliberately does NOT flag `_reLayout` bodies (they would false-positive
// on the super-delegation, and the base issues no blanket `@fullChanged()`). Both the empirically
// observed D2 bug class (5 bodies) and the [INV-1] precedent are `_reLayoutSelf`; anything the static
// shape cannot reach is covered by the runtime paint-truthfulness audit
// (Fizzygum-tests/scripts/run-paint-audit.js, a `fg gauntlet` gate). Only `_reLayoutSelf` bodies that
// CALL `disableTrackChanges` are checked (the suppression frame is what can swallow the repaint); a
// body that never suppresses, or that re-enables in a DIFFERENT method (no `maybeEnableTrackChanges`
// here — the enable + covering repaint live at the outer call site), is out of reach and reported as
// "deferred-enable" (advisory, not a failure). Comments are stripped before matching.
//
// EXEMPTION: a `# relayout-repaint-exempt: <reason>` marker (non-empty reason) in the contiguous
// comment block directly above the method header.

const fs = require('fs');
const path = require('path');
const SRC = path.resolve(__dirname, '../src');

const HEADER  = /^  ([A-Za-z_]\w*): (\(.*?\) )?[-=]>/;          // 2-space-indent class method header
const EXEMPT  = /#\s*relayout-repaint-exempt:\s*\S/;            // marker WITH a non-empty reason
const DISABLE = /\bdisableTrackChanges\b/;                      // opens a change-suppression frame
const ENABLE  = /\bmaybeEnableTrackChanges\b/;                  // re-arms the outermost frame
const REPAINT = /\bfullChanged\s*\(/;                           // the covering repaint (@ or world.)

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
let checked = 0, noSuppress = 0, deferredEnable = 0, exempt = 0;
for (const p of walk(SRC, [])) {
  const cls = path.basename(p, '.coffee');
  const lines = fs.readFileSync(p, 'utf8').split('\n');
  const heads = [];
  lines.forEach((l, i) => { const m = HEADER.exec(l); if (m) heads.push({ name: m[1], i }); });
  for (let k = 0; k < heads.length; k++) {
    if (heads[k].name !== '_reLayoutSelf') continue;            // scope: the covering-repaint owner (see header)
    const head = heads[k];
    // EXEMPTION: scan upward through the contiguous comment block directly above the header.
    let marked = false;
    for (let j = head.i - 1; j >= 0 && /^\s*#/.test(lines[j]); j--) {
      if (EXEMPT.test(lines[j])) { marked = true; break; }
    }
    if (marked) { exempt++; continue; }
    const end = k + 1 < heads.length ? heads[k + 1].i : lines.length;
    // Scan the body (code only): does it suppress tracking? where is the LAST re-enable? any repaint after it?
    let sawDisable = false, lastEnable = -1, repaintAfterEnable = false;
    for (let j = head.i + 1; j < end; j++) {
      const code = stripComment(lines[j]);
      if (!code.trim()) continue;
      if (DISABLE.test(code)) sawDisable = true;
      if (ENABLE.test(code)) { lastEnable = j; repaintAfterEnable = false; }   // reset: only a repaint AFTER the last enable counts
      else if (lastEnable !== -1 && REPAINT.test(code)) repaintAfterEnable = true;
    }
    if (!sawDisable) { noSuppress++; continue; }                 // no suppression frame -> nothing can be dropped
    if (lastEnable === -1) { deferredEnable++; continue; }       // re-enable + repaint are at the outer call site
    if (repaintAfterEnable) { checked++; continue; }
    violations.push({ cls, name: head.name, file: path.relative(SRC, p), line: head.i + 1, enableLine: lastEnable + 1 });
  }
}

console.log(`[relayout-repaints] ${checked} suppress+covering-repaint + ${noSuppress} no-suppression + ${deferredEnable} deferred-enable + ${exempt} exempt _reLayoutSelf override(s) checked.`);
if (violations.length) {
  console.error(`\n[relayout-repaints] FAIL -- ${violations.length} _reLayoutSelf override(s) suppress change-tracking but issue NO covering fullChanged() after re-enabling it (a raw-applied move would leave a stale/ghost region -- [INV-1] / the 2026-07 D2 bug class):`);
  for (const v of violations) {
    console.error(`  ${v.cls}.${v.name}  (${v.file}:${v.line}) -- last maybeEnableTrackChanges at line ${v.enableLine}, no fullChanged() after it`);
  }
  console.error('\nFIX: add a covering repaint immediately after the re-enable -- e.g.:');
  console.error('       world.maybeEnableTrackChanges()');
  console.error('       @fullChanged()                    # [INV-1]: repaint what the raw geometry applies above moved');
  console.error('     (see HorizontalMenuPanelWdgt._reLayoutSelf and the five F2 bodies for the fixed shape).');
  console.error('Or add  # relayout-repaint-exempt: <reason>  directly above the method header.');
  process.exit(1);
}
console.log('[relayout-repaints] OK -- every tracking-suppressing _reLayoutSelf issues its covering fullChanged() after re-enable ([INV-1]).');
process.exit(0);

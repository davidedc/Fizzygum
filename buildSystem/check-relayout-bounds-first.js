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
//     @_applyGrantedBounds <newBounds>              -- the common form (base Widget re-commits idempotently via super)
//   | @_applyMoveTo … AND @_applyExtent …    -- position + size, the InspectorWdgt form
//   | super / super <newBounds> / Widget::_reLayout.call …   -- base applies bounds, the super-at-TOP form
// The `@_` prefix is what distinguishes a SELF apply from a child apply (`child._applyGrantedBounds` does NOT count).
//
// A `_reLayout` that positions children from the `newBoundsForThisLayout` PARAM (never from @-geometry) --
// or that positions no children at all -- has no own-geometry read and passes trivially (the video-player
// widgets, the scroll / vertical-stack containers whose child layout lives in _positionAndResizeChildren,
// the caret which reads its PARENT/TARGET geometry). `@boundingBox()` and `@extent()` are the nil-default
// normalisers, NOT child-positioning reads, so they do not count as own-geometry reads.
//
// THE TEMPLATE FORM. A widget that lays out its OWN CONTENTS delegates the whole shape to
// `Widget._reLayoutWithOwnContents` and overrides the `_layOutOwnContents` hook instead:
//     _reLayout: (newBoundsForThisLayout) ->
//       @_reLayoutWithOwnContents newBoundsForThisLayout
//     _layOutOwnContents: ->
//       …positions children from @width()/@height()/@topLeft()…
// The template applies the granted bounds before calling the hook, so apply-first holds BY
// CONSTRUCTION for every overrider rather than being re-checked per body. Such a `_reLayout` is
// counted as `template` (never as the trivial "positions no children" bucket -- that would let 16
// classes silently leave this gate's coverage the day they converted).
//
// The hazard the template introduces instead is a class that overrides `_layOutOwnContents` but does
// NOT route through the template, so nothing applies its bounds first: a `_layOutOwnContents` that
// reads own geometry in a file whose own `_reLayout` does not delegate is a violation.
// A file defining the hook and NO `_reLayout` of its own (the three PatchNodeWdgt subclasses) is
// RESOLVED, not trusted: the scanner reads every `class X extends Y` line first, then walks up to the
// nearest ancestor that actually defines `_reLayout` and asks whether THAT one delegates. Reaching
// Widget without finding one means the base pass runs and the hook is never called at all -- dead
// code, and a violation too.
//
// EXEMPTION: a `# relayout-bounds-first-exempt: <reason>` marker (non-empty reason) in the comment block
// directly above the `_reLayout` header. The base `Widget::_reLayout` (the applier itself) is skipped.
//
// Reference FIXED shapes: FanoutWdgt._reLayout (@_applyGrantedBounds near the top) and InspectorWdgt._reLayout
// (@_applyMoveTo + @_applyExtent near the top). This is the DEF-side companion to that fix arc.

// It reads the compiled sources (lib/source-files.js compiledFiles: src/ and the tests repo's harness).
//
// Run from the Fizzygum/ repo root (build_it_please.sh does): node ./buildSystem/check-relayout-bounds-first.js
// [--src=DIR] [--tests-repo=DIR] — the rails check another src tree or tests repo (a copy carrying a plant). That
// both rules BITE, and that every accepted shape passes (counted), is proven on every build by
// check-relayout-bounds-first-selftest.js.

const fs = require('fs');
const path = require('path');
const { rejectUnknownArgs, rejectPositionalArgs } = require('./lib/cli-args');
const { compiledFiles, sourceRoots, sourceName, SOURCE_RAILS } = require('./lib/source-files');
const rules = require('./lib/gate-rules').forGate(__filename);

const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, [...SOURCE_RAILS], 'relayout-bounds-first');
rejectPositionalArgs(ARGV, 'relayout-bounds-first', 'a src tree is named with --src=DIR');
const ROOTS = sourceRoots(ARGV, 'relayout-bounds-first');

const { methodSpans } = require('./lib/coffee-method-header');   // class methods, one span each
const EXEMPT = /#\s*relayout-bounds-first-exempt:\s*\S/;     // marker WITH a non-empty reason
// own-geometry accessor reads that indicate positioning children against MY (about-to-change) frame:
const GEOM = /@(?:left|right|top|bottom|width|height|position|topLeft|topRight|bottomLeft|bottomRight|center)\(\)|@bounds\b(?!\s*=)/;
// SELF-bounds applications -- the `@_` prefix distinguishes self from a `child.apply`:
const APPLY_BOUNDS = /@_apply(Granted)?Bounds\b/;   // granted (arrange frame-commit) OR the setBounds twin — both commit own bounds
const APPLY_MOVE   = /@_applyMoveTo\b/;
const APPLY_EXTENT = /@_applyExtent\b/;
const SUPER        = /\bsuper\b|Widget::_reLayout\b/;
const DELEGATES    = /@_reLayoutWithOwnContents\b/;          // the own-contents template applies bounds for me
const HOOK         = '_layOutOwnContents';                   // …and calls THIS with the frame already committed

// every rule reads a line's bare code (lib/coffee-mask.js: comments and literal contents blanked); the marker its comment
const { coffeeMask, isCommentOnly } = require('./lib/coffee-mask');

// PASS 1 — parse every file once, so the hook rule below can resolve an INHERITED `_reLayout`
// instead of assuming one. (Without this the three PatchNodeWdgt subclasses — which define the hook
// and no `_reLayout` — would be waved through on trust.)
const FILES = [];
const byClass = new Map();
for (const p of compiledFiles(ROOTS)) {
  const text = fs.readFileSync(p, 'utf8');
  const lines = text.split('\n');
  const masked = coffeeMask(text, sourceName(p, ROOTS));
  const bare = masked.map((l) => l.bare);
  const heads = [];
  for (const sp of methodSpans(lines)) heads.push({ name: sp.name, i: sp.line, end: sp.end });
  const bodyEnd = (k) => heads[k].end;
  const decl = /^class\s+(\w+)(?:\s+extends\s+(\w+))?/m.exec(lines.join('\n'));
  const rec = {
    p, lines, masked, bare, heads, bodyEnd,
    cls: decl ? decl[1] : path.basename(p, '.coffee'),
    parent: decl ? decl[2] : undefined,
    hasOwnReLayout: heads.some((h) => h.name === '_reLayout'),
    delegatesToTemplate: heads.some((h, k) =>
      h.name === '_reLayout' &&
      bare.slice(h.i + 1, bodyEnd(k)).some((l) => DELEGATES.test(l))),
  };
  FILES.push(rec);
  byClass.set(rec.cls, rec);
}
// The nearest ancestor that actually defines `_reLayout` decides: does the shape I am a hook for
// route through the template? Reaching Widget without one means the base runs and never calls the
// hook at all — the hook is dead code, which is also worth failing on.
function reachesTemplate(rec) {
  for (let c = rec.parent, guard = 0; c && guard < 40; c = byClass.get(c)?.parent, guard++) {
    const a = byClass.get(c);
    if (!a) return false;
    if (a.hasOwnReLayout) return a.delegatesToTemplate;
  }
  return false;
}

const violations = [];
let checked = 0, exempt = 0, trivial = 0, template = 0;
for (const rec of FILES) {
  const { p, lines, masked, bare, heads, bodyEnd, cls, delegatesToTemplate } = rec;
  if (cls === 'Widget') continue;                           // the base _reLayout IS the applier
  for (let k = 0; k < heads.length; k++) {
    if (heads[k].name !== '_reLayout' && heads[k].name !== HOOK) continue;
    const head = heads[k];
    if (head.name === HOOK) {
      // The template applies my bounds before calling me, so routing through it IS apply-first.
      // Counted with the _reLayout that delegates, not here; only a NON-delegating file is a finding.
      if (delegatesToTemplate) continue;
      const geomAt = bare.slice(head.i + 1, bodyEnd(k)).findIndex((l) => GEOM.test(l));
      if (geomAt === -1) continue;                            // reads no own geometry -> nothing to lag
      // no _reLayout of my own: RESOLVE the inherited one rather than trusting it
      if (!rec.hasOwnReLayout && reachesTemplate(rec)) { template++; continue; }
      const g = head.i + 1 + geomAt;
      violations.push({ cls, file: sourceName(p, ROOTS), method: HOOK, line: head.i + 1, geomLine: g + 1, geom: lines[g].trim() });
      continue;
    }
    // EXEMPTION: scan upward through the contiguous comment block directly above the header.
    let marked = false;
    for (let j = head.i - 1; j >= 0 && isCommentOnly(masked[j]); j--) {
      if (EXEMPT.test(masked[j].comment)) { marked = true; break; }
    }
    if (marked) { exempt++; continue; }
    const end = bodyEnd(k);
    // Walk the body: has a SELF-apply been seen by the time we hit the first own-geometry read? Delegating to the
    // own-contents template commits the granted bounds before the hook runs -- apply-first by construction, counted
    // separately so a conversion cannot quietly land in the `trivial` bucket -- but only a delegation reached BEFORE
    // any own-geometry read: a read ahead of it reads the previous pass's frame like any other.
    let firstGeom = -1, appliedBeforeGeom = false, delegated = false;
    let sawBounds = false, sawMove = false, sawExtent = false, sawSuper = false;
    for (let j = head.i + 1; j < end; j++) {
      const code = bare[j];
      if (!code.trim()) continue;
      if (DELEGATES.test(code) && !GEOM.test(code.replace(DELEGATES, ''))) { delegated = true; break; }
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
    if (delegated) { template++; continue; }
    if (firstGeom === -1) { trivial++; continue; }           // no own-geometry positioning -> safe
    if (appliedBeforeGeom) { checked++; continue; }
    violations.push({ cls, file: sourceName(p, ROOTS), line: head.i + 1, geomLine: firstGeom + 1, geom: lines[firstGeom].trim() });
  }
}

console.log(`[relayout-bounds-first] ${checked} apply-first + ${template} own-contents template + ${trivial} param-driven/no-child + ${exempt} exempt _reLayout override(s) checked.`);
if (violations.length) {
  console.error(`\n[relayout-bounds-first] FAIL -- ${violations.length} override(s) read own geometry BEFORE applying own bounds (children would lag one cadence on resize):`);
  for (const v of violations) {
    const line = `  ${v.cls}.${v.method || '_reLayout'}  (${v.file}:${v.line}) -- first own-geometry read at line ${v.geomLine}:  ${v.geom}`;
    console.error(v.method === HOOK ? rules.fired('HOOK_WITHOUT_TEMPLATE', line) : rules.fired('READS_BEFORE_APPLY', line));
  }
  console.error('\nFIX: apply own bounds FIRST -- e.g. right after the collapse guard:');
  console.error('       newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout');
  console.error('       @_applyGrantedBounds newBoundsForThisLayout');
  console.error('     (see FanoutWdgt._reLayout / InspectorWdgt._reLayout for the fixed shapes; the trailing super re-commits idempotently).');
  console.error('Or, if this is a widget positioning its OWN contents, take the template shape instead:');
  console.error('       _reLayout: (newBoundsForThisLayout) ->');
  console.error('         @_reLayoutWithOwnContents newBoundsForThisLayout');
  console.error('       _layOutOwnContents: ->  …  (bounds are already committed when this runs)');
  console.error('Or, for a _reLayout only, add  # relayout-bounds-first-exempt: <reason>  directly above its header (a');
  console.error('_layOutOwnContents hook takes no marker: route its class through the template).');
  process.exit(1);
}
console.log('[relayout-bounds-first] OK -- every _reLayout applies its own bounds before reading its own geometry.');
process.exit(0);

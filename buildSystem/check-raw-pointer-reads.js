#!/usr/bin/env node
// check-raw-pointer-reads.js — build lint: a POINTER-EVENT HANDLER body must not consume the raw
// screen-plane pointer. Mirrors check-relayout-bounds-first.js (line scanner; exit 0 clean / 1 violation).
//
// THE RULE. Since affine Phase 4A the dispatcher hands every pointer handler the pointer position
// ALREADY inverse-mapped into the receiver's own plane (ActivePointerWdgt._pointerPositionInPlaneOf —
// for each receiver of a press's climb and of its endings, since the hand drives both; a handler that
// escalates instead, `activated` and kin, forwards it verbatim within one island plane).
// `world.hand.position()` is the raw
// SCREEN-plane point: mixing it with plane-local geometry (@position()/bounds) works for aligned
// widgets — off any island the mapped point IS the raw point — and silently breaks for tilted ones
// (the 2026-07-17 spreadsheet tilted-selection bug; the invisible-until-tilted bug class this gate
// exists to kill). So inside a handler body, `world.hand.position()` may appear ONLY mapped at the
// read site — `screenPointToMyPlane` on the SAME line (the per-frame sampling idiom: a drag-scroll
// step legitimately samples the hand each frame, but must map each sample — ViewportWdgt). A
// handler that needs the pointer as a position should otherwise consume its `pos` PARAMETER — and one
// that is handed none (`pressCancelled`, the press's cancel: a pure fact, no position) must map its
// own read the same way.
//
// SCOPE. Method bodies — a class's 2-space-indent methods and a mixin's onceAddedClassProperties
// members alike, grouped by the shared lib/coffee-method-header.js methodBoundary (a mixin's handlers
// run on every widget it augments) — whose names are the
// dispatched pointer-handler names below — closures defined inside them (a _settleLayoutsAfter thunk)
// are inside the span and covered — plus the two ViewportWdgt drag-scroll methods that sample or
// consume the pointer per frame / per event although no dispatcher calls them by a handler name:
// takeStrokeScrollFrom (it installs the drag-scroll @step, a closure sampling the hand every frame)
// and latchStrokeScroll (the hand hands it the press and grab-radius-crossing points at the drained
// event that latches the stroke). HELPERS a handler calls are NOT
// scanned (a heuristic tripwire, not a proof): the known deliberate raw-screen consumer
// (HandleWdgt._pointerAngleToTargetAnchorDegrees — the rotate handle measures an angle in SCREEN
// space by design, see its comment) lives in such a helper. ActivePointerWdgt.coffee is skipped
// wholesale (it IS the hand/dispatcher). Screen-space PLACEMENT of new top-level widgets
// (open-a-window-at-the-hand) lives outside handler-named methods and is untouched.
// Both hand-kept names here are held to the sources it scans, and a stale one FAILS (STALE_ALLOWLIST_ENTRY): an EXTRA
// handler name no scanned method carries would leave the method it meant silently unscanned, and a
// SKIPPED class that does not exist means the skip names something that moved.
//
// EXEMPTION: a `# raw-screen-pointer-sanctioned: <reason>` marker (non-empty reason) in the comment
// block directly above the handler header. No current site needs it.
//
// The bodies scanned are those of the compiled sources (lib/source-files.js compiledFiles: src/ and the tests repo's
// harness); the dispatcher the handler table is held to is src's ActivePointerWdgt.

//
// Run from the Fizzygum/ repo root (build_it_please.sh does): node ./buildSystem/check-raw-pointer-reads.js
// [--src=DIR] [--tests-repo=DIR] — the rails check another src tree or tests repo (a copy carrying a plant). That
// every rule BITES — a raw read, each way the handler table can disagree with the dispatcher, a stale
// EXTRA_HANDLER_NAMES entry — and that every accepted form passes, is proven on every build by
// check-raw-pointer-reads-selftest.js.

const fs = require('fs');
const path = require('path');
const { rejectUnknownArgs, rejectPositionalArgs } = require('./lib/cli-args');
const { compiledFiles, sourceRoots, sourceName, SOURCE_RAILS } = require('./lib/source-files');
const rules = require('./lib/gate-rules').forGate(__filename);

const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, [...SOURCE_RAILS], 'raw-pointer-reads');
rejectPositionalArgs(ARGV, 'raw-pointer-reads', 'a src tree is named with --src=DIR');
const ROOTS = sourceRoots(ARGV, 'raw-pointer-reads');
const SRC = ROOTS.src;

const { methodBoundary } = require('./lib/coffee-method-header');   // class AND mixin-member method grouping
const EXEMPT = /#\s*raw-screen-pointer-sanctioned:\s*\S/;    // marker WITH a non-empty reason
const RAW_READ = /world\.hand\.position\(\)/;
const MAPPED = /screenPointToMyPlane/;
// the dispatched handlers come from the ONE table both body gates read (lib/pointer-handlers.js),
// which this gate also holds against ActivePointerWdgt, both ways, below
const pointerHandlers = require('./lib/pointer-handlers');
// not dispatched by name, but the per-frame / per-event pointer consumers of the drag-scroll (see SCOPE)
// hand-list-sanctioned: check-raw-pointer-reads.js fails STALE_ALLOWLIST_ENTRY on a name no scanned class defines
const EXTRA_HANDLER_NAMES = ['takeStrokeScrollFrom', 'latchStrokeScroll'];
const HANDLER_NAMES = new Set([...pointerHandlers.HANDLER_NAMES, ...EXTRA_HANDLER_NAMES]);
// the hand/dispatcher itself: never stale, since a src tree without ActivePointerWdgt.coffee fails the table check below
const SKIPPED_CLASSES = ['ActivePointerWdgt'];
rules.declare(pointerHandlers.PROBLEM_KINDS);
const tableProblems = pointerHandlers.dispatchProblems(SRC);
if (tableProblems.length) {
  console.error(`raw-pointer-reads gate: the pointer-handler table (buildSystem/lib/pointer-handlers.js) disagrees with ActivePointerWdgt:`);
  for (const p of tableProblems) console.error(rules.fired(p.kind, '  ' + p.text));
  process.exit(1);
}

const { coffeeMask, isCommentOnly } = require('./lib/coffee-mask');

const violations = [];
let checked = 0, exempt = 0;
const files = compiledFiles(ROOTS);
const headersSeen = new Set();   // every method name a scanned file defines (EXTRA_HANDLER_NAMES are held to it)
for (const p of files) {
  const cls = path.basename(p, '.coffee');
  if (SKIPPED_CLASSES.includes(cls)) continue;
  const text = fs.readFileSync(p, 'utf8');
  const lines = text.split('\n');
  const masked = coffeeMask(text, sourceName(p, ROOTS));   // a read is matched on bare code; the marker in a comment
  let inHandler = false, handlerName = null, handlerExempt = false;
  let commentBlockHasExempt = false;
  let mixinHashIndent = null;
  for (let n = 0; n < lines.length; n++) {
    const line = lines[n];
    const boundary = methodBoundary(line, mixinHashIndent);
    if (boundary) mixinHashIndent = boundary.mixinHashIndent;
    if (boundary && boundary.kind === 'header') {
      headersSeen.add(boundary.method);
      inHandler = HANDLER_NAMES.has(boundary.method);
      handlerName = boundary.method;
      handlerExempt = commentBlockHasExempt;
      if (inHandler) { checked++; if (handlerExempt) exempt++; }
      commentBlockHasExempt = false;
      continue;
    }
    if (boundary) inHandler = false;                          // a non-method key or a column-0 line ends the method
    // track the comment block directly above the NEXT header: any code line breaks it, so a marker
    // inside the previous method's body exempts nothing
    if (isCommentOnly(masked[n])) { if (EXEMPT.test(masked[n].comment)) commentBlockHasExempt = true; }
    else if (line.trim() !== '') { commentBlockHasExempt = false; }
    else { /* blank keeps the block */ }
    if (!inHandler || handlerExempt) continue;
    const code = masked[n].bare;
    if (RAW_READ.test(code) && !MAPPED.test(code)) {
      const rel = sourceName(p, ROOTS, 'src/');
      violations.push(rules.fired('RAW_READ', `[raw-pointer] ${cls}.${handlerName} reads world.hand.position() unmapped — ${rel}:${n + 1}\n`
        + `    consume the plane-mapped \`pos\` parameter, or map the sample at the read site:\n`
        + `    @screenPointToMyPlane world.hand.position()  (off-island this is the same point;\n`
        + `    tilted it is the difference between the right cell and the wrong one)`));
    }
  }
}

const stale = EXTRA_HANDLER_NAMES.filter((n) => !headersSeen.has(n))
  .map((n) => `EXTRA_HANDLER_NAMES '${n}' — no scanned class defines a method of that name, so the body it meant goes unscanned: point the entry at the method's new name (or delete it)`);
if (violations.length || stale.length) {
  if (violations.length) {
    console.error(`raw-pointer-reads gate: ${violations.length} violation(s) in ${checked} handler bodies scanned:`);
    for (const v of violations) console.error('  ' + v);
  }
  if (stale.length) {
    console.error(`raw-pointer-reads gate: ${stale.length} stale entr${stale.length === 1 ? 'y' : 'ies'} in this gate's own tables:`);
    for (const s of stale) console.error(rules.fired('STALE_EXTRA_HANDLER_NAME', '  STALE_ALLOWLIST_ENTRY ' + s));
  }
  process.exit(1);
}
console.log(`  raw-pointer-reads gate OK — ${checked} pointer-handler bodies scanned, ${exempt} exempt, 0 raw reads.`);
process.exit(0);

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
//    geometry (the `bounds` field, and the position queries READ from Widget.coffee — see
//    POSITIONAL below: position/left/topCenter/fullBounds/… — plane-RELATIVE, unlike width/
//    height/extent which are plane-invariant) of two DISTINCT receivers combined on one line,
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
// C. A POINTER POSITION NOT IN THE RECEIVER'S PLANE (hard zero). The hand hands most positional
//    handlers the pointer ALREADY mapped into the receiver's own plane — every receiver of a press's
//    climb and of its endings (pressBegan, pressEnded), every receiver of a move (hoverMoved,
//    pressMoved), the implementor a click or a context gesture lands on — so those consume their
//    `pos` as given and are not checked here. Two ways remain for a `pos` to be in some OTHER plane:
//    C1. ESCALATION. `escalateEvent` forwards its args VERBATIM up the parent chain, so a positional
//        handler reached by escalation, defined on a scroll-translation PROVIDER (a class providing
//        `scrollTranslationOfChild`, or a subclass), can receive a `pos` still expressed in a
//        descendant's plane — offset-pixels away from its own (the measured
//        stationary-click-slams-to-clamp defect). Which handlers are reached that way is READ from
//        src, never listed: every name an `escalateEvent "<name>"` call forwards, among the handlers
//        whose first parameter is the pointer position — so a handler that starts being escalated
//        is checked from that moment. Rule (the viewports-and-planes.md input rule, given teeth): such
//        a handler on a provider must not read its pos parameter at all — it re-derives the point
//        from the hand (`@screenPointToMyPlane world.hand.position()`); mapping the escalated pos
//        itself would treat a descendant's plane as the screen. A body that only escalates its pos
//        on is not reading it.
//    C2. THE RAW SCREEN POINT. The hand hands `nonFloatDragging` the raw SCREEN pointer (its second
//        parameter, `pos`), on any class: every line reading it must map it into the receiver's plane
//        on that same line (`@screenPointToMyPlane pos`) — off any island and outside any scrolled
//        pane the two are the same point, so the bug is invisible until the widget sits in one.
//    A MIXIN's members are checked as the classes it augments (`@augmentWith`) would check them: C1 applies
//    when any augmenting class is a provider, C2 always (lib/coffee-method-header.js groups mixin members).
//    `scrolledBy` is exempt (deltas, not positions). Exemption marker for a future deliberate
//    consumer: `# escalated-pos-sanctioned: <reason>` directly above the handler header.
//
// Exit codes: 0 clean · 1 violation (or a stale NOT_POSITIONAL / NON_WIDGET_ROOTS entry) · 2 operational (Widget.coffee
// unreadable, or the POSITIONAL derivation found nothing — which would make rule B vacuous).
//
// Run from the Fizzygum/ repo root (build_it_please.sh does): node ./buildSystem/check-plane-discipline.js [--src=DIR]
// — the rail checks another src tree (a copy carrying a plant). That every rule BITES, and that every accepted form
// passes, is proven on every build by check-plane-discipline-selftest.js.
// bite-unplantable: B_STALE_NON_WIDGET_ROOT — NON_WIDGET_ROOTS is empty, and a plant reaches only the src tree, never this gate's own table; the rule fires the day an entry is added and its excused line goes

const fs = require('fs');
const path = require('path');
const { rejectUnknownArgs, rejectPositionalArgs, dirArg } = require('./lib/cli-args');
const rules = require('./lib/gate-rules').forGate(__filename);

const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, ['--src='], 'plane-discipline');
rejectPositionalArgs(ARGV, 'plane-discipline', 'a src tree is named with --src=DIR');
const SRC = dirArg(ARGV, '--src=', path.resolve(__dirname, '../src'), 'plane-discipline');
const { methodBoundary, methodSpans } = require('./lib/coffee-method-header');

// ---- baseline for section B (the check-stinks idiom: exact count, move it consciously) ----
// 31 lines. Three of them are reached through Widget's centre queries: FridgeWdgt's magnet-to-magnet
// distances (`m.rightCenter().distanceTo(aMagnet.leftCenter())` in magnetToLeftOf, its mirror in
// magnetFollowing, and magnetFollowing's reciprocity test). Every magnet compared there is a child of the
// one fridge, so all share its plane — the same comparison as the fridge's edge tests
// (`m.right() < aMagnet.right()`) counted beside them.
const CROSS_PLANE_MIX_BASELINE = 31;

// ---- POSITIONAL: Widget's own position queries, READ from Widget.coffee, never hand-listed ----
// THE RULE: a Widget instance method taking no parameter that answers a point, an edge or a rectangle
// of the widget in its OWN plane, recognised by either of two shapes:
//   (1) a FRAME DELEGATION — a body of ONE line that reads `@bounds` (`left: -> @bounds.left()`,
//       `position: -> @bounds.origin`, `leftTight: -> @bounds.left() + @paddingLeft`);
//   (2) a `…Bounds` RECTANGLE — a name ending in `Bounds` (`fullBounds`, `clippedThroughBounds`, …);
// minus NOT_POSITIONAL, the names those shapes catch that are not plane-relative positions.
// WHY READ: a hand-kept list drifts both ways — it keeps names Widget does not define (a Rectangle FIELD
// such as `origin`, which a `\.name\s*\(` pattern never matches) and misses the queries Widget adds.
// Read from the definitions, a new query is checked from the day it is written, and one Widget loses
// leaves no dead arm behind. NOT_POSITIONAL is a declaration held against the derivation: an entry the
// shapes no longer catch FAILS as stale. (A new `…Bounds` name that is not a position is the safe
// direction: it can only ADD lines to rule B's count, where a reader classifies them.)
// ⚠ VACUITY: a shape deriving nothing exits 2 — a rule B keyed on an empty vocabulary would match
// nothing and report a clean count of whatever the `bounds` field alone finds.
const NOT_POSITIONAL = {
  extent: 'a SIZE — plane-invariant, which is what rule B is defined against',
  width: 'a SIZE — plane-invariant, which is what rule B is defined against',
  height: 'a SIZE — plane-invariant, which is what rule B is defined against',
  screenBounds: 'the SCREEN-family query: already mapped (MAPPED_RE treats a line using it as mapped)',
  hasMaybeChangedPaintBounds: 'a predicate: it answers a boolean, not a rectangle',
};
function derivePositional() {
  const file = path.join(SRC, 'basic-widgets', 'Widget.coffee');
  if (!fs.existsSync(file)) { console.error(`[plane-discipline] operational error: ${file} not found — rule B reads its position queries from it`); process.exit(2); }
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  // `foo: ->` and `foo: () ->` take none; `foo: (a) ->` and a wrapped `foo: (` do
  const takesNoParameter = (header) => { const m = stripComment(header).match(/^\s*@?\w+:\s*\((.*)$/); return !m || /^\s*\)/.test(m[1]); };
  const delegations = new Set(), rectangles = new Set();
  for (const s of methodSpans(lines)) {
    if (s.static || s.mixin || !takesNoParameter(lines[s.line])) continue;
    const inline = (stripComment(lines[s.line]).match(/[-=]>(.*)$/) || [])[1] || '';   // a body written after the arrow
    const body = [inline].concat(lines.slice(s.line + 1, s.end).map(stripComment)).filter((l) => l.trim());
    if (body.length === 1 && /@bounds\b/.test(body[0])) delegations.add(s.name);
    if (/Bounds$/.test(s.name)) rectangles.add(s.name);
  }
  const vacuous = [['frame delegations', delegations], ['…Bounds rectangles', rectangles]].filter(([, set]) => set.size === 0);
  if (vacuous.length) { console.error(`[plane-discipline] operational error: the POSITIONAL derivation found no ${vacuous.map(([n]) => n).join(' and no ')} on Widget — rule B would be vacuous; re-read derivePositional's rule against Widget.coffee`); process.exit(2); }
  const derived = new Set([...delegations, ...rectangles]);
  const stale = Object.keys(NOT_POSITIONAL).filter((n) => !derived.has(n));
  return { names: [...derived].filter((n) => !Object.prototype.hasOwnProperty.call(NOT_POSITIONAL, n)).sort((a, b) => b.length - a.length || a.localeCompare(b)), stale };
}
const { names: POSITIONAL_NAMES, stale: STALE_EXCLUSIONS } = derivePositional();
const POSITIONAL = POSITIONAL_NAMES.join('|');
const CALL_RE = new RegExp('(@?[A-Za-z_$][A-Za-z0-9_$]*)((?:\\.[A-Za-z_$][A-Za-z0-9_$]*)*?)\\.(' + POSITIONAL + ')\\s*\\(', 'g');
const BOUNDS_RE = new RegExp('(@?[A-Za-z_$][A-Za-z0-9_$]*)((?:\\.[A-Za-z_$][A-Za-z0-9_$]*)*?)\\.(bounds)\\b(?!\\s*=[^=])', 'g');
const BARE_RE = new RegExp('(?<![A-Za-z0-9_$.])@(' + POSITIONAL + ')\\s*\\(', 'g');
const BARE_BOUNDS_RE = /(?<![A-Za-z0-9_$.])@bounds\b(?!\s*=[^=])/;
const MAPPED_RE = /screenPointToMyPlane|localPointToScreen|mapRectToScreen|screenBounds|scrollTranslationOfChild|_scrollTranslation|scrollOffset/;
// receivers that are no widget (a class or a host object), never counted as a positional root of rule B. A root
// listed here must be one some scanned line actually calls a position query (or `.bounds`) on, or it FAILS as
// stale (STALE_ALLOWLIST_ENTRY): an entry that excuses nothing today would excuse the next line that mixes it.
// Empty: no line in src calls a position query or `.bounds` on a class or host object (Math, Rectangle, Point,
// window, JSON, Object each excuse nothing), and a line that did would be COUNTED by rule B — the safe
// direction, where a reader classifies it — until a root is added here with the line it excuses.
const NON_WIDGET_ROOTS = new Set([]);
const nonWidgetRootsUsed = new Set();

// the pointer handlers whose FIRST parameter is the pointer position (C1 checks the ones of them that
// some `escalateEvent` call forwards), and the handler handed the raw SCREEN pointer with the
// position of that parameter (C2) -- both read from the ONE handler table (lib/pointer-handlers.js),
// which check-raw-pointer-reads.js holds against what ActivePointerWdgt actually dispatches
const pointerHandlers = require('./lib/pointer-handlers');
const POS_HANDLER_NAMES = new Set(pointerHandlers.PLANE_POS_HANDLER_NAMES);
const ESCALATE_CALL_RE = /escalateEvent\s*\(?\s*["']([A-Za-z_$][A-Za-z0-9_$]*)["']/g;
const RAW_SCREEN_POS_HANDLERS = pointerHandlers.RAW_SCREEN_POS_HANDLERS;
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
const escalatedNames = new Set();   // every handler name some `escalateEvent "<name>"` call forwards (C1)
const classParent = new Map();   // class -> extends parent
const classFile = new Map();     // class -> file path
const mixinFile = new Map();     // mixin -> file path (a mixin's members are checked as every class it augments would be)
const augmentedBy = new Map();   // mixin -> Set of classes whose body says `@augmentWith <mixin>`

// pass 1: scan lines; collect class graph + provider definers
for (const p of files) {
  const rel = path.relative(SRC, p);
  const lines = fs.readFileSync(p, 'utf8').split('\n');
  let inMethod = '', mixinHashIndent = null;
  lines.forEach((raw, i) => {
    const cls = raw.match(/^class\s+([A-Za-z0-9_$]+)(?:\s+extends\s+([A-Za-z0-9_$]+))?/);
    if (cls) { classFile.set(cls[1], p); if (cls[2]) classParent.set(cls[1], cls[2]); }
    const mix = raw.match(/^([A-Za-z0-9_$]+Mixin)\s*=\s*$/);
    if (mix) mixinFile.set(mix[1], p);
    const aug = raw.match(/@augmentWith\s+([A-Za-z0-9_$]+Mixin)\b/);
    if (aug) { for (const [c, f] of classFile) if (f === p) { if (!augmentedBy.has(aug[1])) augmentedBy.set(aug[1], new Set()); augmentedBy.get(aug[1]).add(c); } }
    const b = methodBoundary(raw, mixinHashIndent);
    if (b) { mixinHashIndent = b.mixinHashIndent; if (b.kind === 'header') inMethod = b.method; }
    if (/^  scrollTranslationOfChild\s*:/.test(raw)) {
      // attribute to the class this file declares (one class per file)
      for (const [c, f] of classFile) if (f === p) providerDefiners.add(c);
    }
    const line = stripComment(raw);
    if (!line.trim()) return;
    ESCALATE_CALL_RE.lastIndex = 0;
    let esc;
    while ((esc = ESCALATE_CALL_RE.exec(line)) !== null) escalatedNames.add(esc[1]);

    // A — bare offset writes
    // any assignment spelling writes the offset: `=`, a compound `+=`/`?=`/`||=`, CoffeeScript's `or=`/`and=`
    if (/(?:@|\.)scrollOffset[XY]\s*(?:[-+*\/%?]|\|\||&&|\bor|\band)?=[^=]/.test(line) && inMethod !== '_writeScrollOffset'
        && !/^\s*scrollOffset[XY]\s*:/.test(raw))
      funnelViolations.push(`${rel}:${i + 1}: [in ${inMethod}] ${raw.trim()}`);

    // B — two-receiver positional mixing
    const roots = new Set();
    for (const re of [CALL_RE, BOUNDS_RE]) {
      re.lastIndex = 0;
      let m;
      while ((m = re.exec(line)) !== null) {
        if (NON_WIDGET_ROOTS.has(m[1])) { nonWidgetRootsUsed.add(m[1]); continue; }
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

// C — a pointer position not in the receiver's plane: escalated pos on provider classes (C1, transitive
// subclasses included), the raw screen pos of nonFloatDragging on any class (C2)
function providesTranslation(cls) {
  let c = cls, hops = 0;
  while (c && hops++ < 50) { if (providerDefiners.has(c)) return true; c = classParent.get(c); }
  return false;
}
const escalatedPosHandlers = new Set([...POS_HANDLER_NAMES].filter((n) => escalatedNames.has(n)));
const paramNamed = (params, index) => ((params.split(',')[index] || '').trim().replace(/=.*$/, '').trim());
const readsName = (name) => new RegExp('(?<![A-Za-z0-9_$])' + name.replace('$', '\\$') + '(?![A-Za-z0-9_$])');
const escalationViolations = [];
let c1Bodies = 0, c2Bodies = 0;
// a mixin member runs on every class that augments the mixin, so it is on a provider exactly when one
// of those classes is
const mixinOnAProvider = (mx) => [...(augmentedBy.get(mx) || [])].some(providesTranslation);
const units = [...classFile].map(([cls, p]) => [cls, p, providesTranslation(cls)])
  .concat([...mixinFile].map(([mx, p]) => [mx, p, mixinOnAProvider(mx)]));
for (const [cls, p, provider] of units) {
  const lines = fs.readFileSync(p, 'utf8').split('\n');
  for (const span of methodSpans(lines)) {
    const i = span.line;
    const mSig = [lines[i], span.name];
    const c1 = provider && escalatedPosHandlers.has(mSig[1]);
    const c2 = RAW_SCREEN_POS_HANDLERS.has(mSig[1]);
    if (!c1 && !c2) continue;
    const params = (lines[i].match(/\(([^)]*)\)/) || [])[1];
    if (!params) continue;                               // zero-param handler: no position to misread
    const posName = paramNamed(params, c2 ? RAW_SCREEN_POS_HANDLERS.get(mSig[1]) : 0);
    if (!posName || posName.startsWith('ignored')) continue;
    let exempt = false;
    for (let k = i - 1; k >= 0 && /^\s*#/.test(lines[k]); k--) if (ESCALATED_EXEMPT.test(lines[k])) exempt = true;
    if (exempt) continue;
    const reads = readsName(posName);
    const passesItOn = new RegExp('escalateEvent\\s*\\(?\\s*["\']' + mSig[1] + '["\']');
    if (c1) c1Bodies++; else c2Bodies++;
    // body span: the method's own (lib/coffee-method-header.js methodSpans)
    for (let j = i + 1; j < span.end; j++) {
      const code = stripComment(lines[j]);
      if (!reads.test(code)) continue;
      if (c1 && passesItOn.test(code)) continue;        // forwarding the pos on is not reading it
      if (c2 && /screenPointToMyPlane/.test(code)) continue;
      escalationViolations.push(c1
        ? { c1, text: `${path.relative(SRC, p)}:${j + 1}: ${cls}.${mSig[1]} reads its escalated '${posName}' (a descendant's plane) — re-derive from the hand: @screenPointToMyPlane world.hand.position()` }
        : { c1, text: `${path.relative(SRC, p)}:${j + 1}: ${cls}.${mSig[1]} reads the raw screen '${posName}' unmapped — map it on the same line: @screenPointToMyPlane ${posName}` });
    }
  }
}

// ---- report ----
let failed = false;
if (funnelViolations.length) {
  failed = true;
  console.error(`[plane-discipline A] FAIL — ${funnelViolations.length} bare scrollOffset write(s) outside _writeScrollOffset:`);
  funnelViolations.forEach((l) => console.error(rules.fired('A_BARE_OFFSET_WRITE', '    ' + l)));
} else console.log('[plane-discipline A] offset funnel: 0 bare writes -- OK');

const staleRoots = [...NON_WIDGET_ROOTS].filter((r) => !nonWidgetRootsUsed.has(r));
if (staleRoots.length) {
  failed = true;
  console.error(`[plane-discipline B] FAIL — NON_WIDGET_ROOTS names ${staleRoots.length} root(s) no scanned line calls a position query or \`.bounds\` on:`);
  for (const r of staleRoots) console.error(rules.fired('B_STALE_NON_WIDGET_ROOT', `    STALE_ALLOWLIST_ENTRY NON_WIDGET_ROOTS '${r}' — it excuses no line today: delete the entry`));
}
if (STALE_EXCLUSIONS.length) {
  failed = true;
  console.error(rules.fired('B_STALE_NOT_POSITIONAL', `[plane-discipline B] FAIL — NOT_POSITIONAL names ${STALE_EXCLUSIONS.length} method(s) the POSITIONAL derivation no longer catches on Widget: ${STALE_EXCLUSIONS.join(', ')} — a stale exclusion; delete the entry (or, if the method was renamed, exclude the new name with the same reason).`));
}
if (mixLines.length !== CROSS_PLANE_MIX_BASELINE) {
  failed = true;
  console.error(`[plane-discipline B] FAIL — cross-plane positional-mix count ${mixLines.length} != baseline ${CROSS_PLANE_MIX_BASELINE}.`);
  if (mixLines.length > CROSS_PLANE_MIX_BASELINE)
    console.error(rules.fired('B_MIX_ROSE', '    New mixed-positional line(s) — classify each: same-plane-by-construction => raise the baseline with a one-line reason in the commit; cross-plane => map it. Current lines:'));
  else
    console.error(rules.fired('B_MIX_DROPPED', '    Count DROPPED — good: lower the baseline to lock it in. Current lines:'));
  mixLines.forEach((l) => console.error('    ' + l));
} else console.log(`[plane-discipline B] cross-plane positional mixing: ${mixLines.length} (baseline ${CROSS_PLANE_MIX_BASELINE}) -- OK (${POSITIONAL_NAMES.length} position queries read from Widget.coffee, ${Object.keys(NOT_POSITIONAL).length} excluded)`);

if (escalationViolations.length) {
  failed = true;
  console.error(`[plane-discipline C] FAIL — ${escalationViolations.length} read(s) of a pointer position not in the receiver's plane:`);
  escalationViolations.forEach((v) => console.error(v.c1 ? rules.fired('C1_ESCALATED_POS', '    ' + v.text) : rules.fired('C2_RAW_SCREEN_POS', '    ' + v.text)));
} else console.log(`[plane-discipline C] positions not in the receiver's plane: 0 reads -- OK (C1: ${c1Bodies} escalated-pos handler bodies [${[...escalatedPosHandlers].sort().join(', ')}] on ${providerDefiners.size} provider class(es) + subclasses + ${[...mixinFile.keys()].filter(mixinOnAProvider).length} mixin(s) augmenting one; C2: ${c2Bodies} raw-screen-pos bodies [${[...RAW_SCREEN_POS_HANDLERS.keys()].join(', ')}]; ${classFile.size} classes + ${mixinFile.size} mixins scanned)`);

process.exit(failed ? 1 : 0);

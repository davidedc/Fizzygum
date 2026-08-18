#!/usr/bin/env node
'use strict';
/*
 * census-nosettle-naming.js — ADVISORY census (not a build gate): the Topic-3 question of
 * docs/archive/settle-tier-followups-examination-plan.md — "does every non-settling private
 * fn carry *NoSettle?" — answered as the two checkable claims that question decomposes into
 * (the plan's own refinement: a blanket rename is NOT the doctrine — the non-settling private
 * surface is several NAMED families, and only a *core of a settling wrapper* must carry the
 * suffix so check-thin-wraps + layering rule [G] can pair it):
 *
 *   A) LYING SUFFIX — a *NoSettle-named def whose body reaches the settle tier
 *      (_settleLayoutsAfter or the join lane). Must be 0: the suffix claims "no settle".
 *   B) MIS-NAMED CORE — a settling wrapper whose SETTLE CLOSURE delegates the mutation to a
 *      private method that is neither a *NoSettle core nor a member of a recognized
 *      non-settling family. This is the escape no gate asserts: check-thin-wraps starts FROM
 *      a `_<name>NoSettle` def and constrains its twin, so a wrapper whose core never took
 *      the suffix is invisible to it; layering [L] only bans the suffix on callbacks.
 *
 * Recognized non-settling families (per the Topic-3 inventory + check-layering.js consts):
 *   *NoSettle cores · the apply-2x2 corners + _apply*Base twins + _commit* corners +
 *   convenience movers/setters · __ leaves (incl. __commit*) · notification callbacks
 *   (_reactTo* and _before*, settle-neutral by rule [J]) · the layout machinery (_reLayout*,
 *   _positionAndResizeChildren, _reLayoutScrollbars, _invalidateLayout, _reFitContainer*,
 *   __markForRelayout) · the settle tiers themselves · _*Connector entrypoints (the [P]
 *   join lane) · *DeferredSettle twins ([O]) · plain _ helpers/queries (which have their OWN
 *   correct names — the plan's stated reason this is a census, not a sweep).
 *
 * Parsing machinery is copied from check-layering.js: stripLine (strips # comments + string
 * literals, carries multi-line string state) + methodBoundary (2-space class methods, mixin
 * onceAddedClassProperties sub-methods), plus the shared lib/coffee-method-header.js.
 *
 * Exit 0 always (advisory). Run from anywhere: node buildSystem/census-nosettle-naming.js
 */

const fs = require('fs');
const path = require('path');

const SRC = path.join(__dirname, '..', 'src');
const { METHOD_HEADER, MIXIN_METHOD_HEADER } = require('./lib/coffee-method-header');

const SETTLE_CALL = /[@.]\s*_settleLayoutsAfter\b/;                       // the single-mutation tier
const JOIN_CALL = /[@.]\s*_settleLayoutsAfterOrJoinEnclosingPass\b/;      // the reactive-connection lane
const SETTLE_TIERS = new Set(['_settleLayoutsAfter', '_settleLayoutsAfterOrJoinEnclosingPass', '_settleLayoutsAfterBatch']);

// The recognized non-settling families (names that legitimately lack the NoSettle suffix).
const CALLBACK = /^_(reactTo|before)[A-Z]/;                               // rule [J]/[L]
const DOUBLE_UNDERSCORE = /^__/;                                          // the [I] leaves, incl. __commit* and __markForRelayout
const IMMEDIATE_MUTATOR = new RegExp('^_apply(Extent|Bounds|Width|Height|MoveBy|MoveTo)(Base)?$'
  + '|^_commit(Extent|Bounds)(AndNotify)?$'
  + '|^_move(LeftSideTo|RightSideTo|TopSideTo|BottomSideTo|ToSideOf|FullCenterTo|Within|InDesktopToFractionalPosition|InStretchablePanelToFractionalPosition)$'
  + '|^_(setWidthSizeHeightAccordingly|setExtentToFractionalExtentInPaneUserHasSet|resizeToWithoutSpacing)$');
const LAYOUT_MACHINERY = /^_(reLayout|positionAndResizeChildren|reLayoutScrollbars|invalidateLayout$|reFitContainer|reFitMyTrackingContainer)/;
const CONNECTOR = /^_\w+Connector$/;                                      // rule [P]
const DEFERRED_SETTLE = /DeferredSettle$/;                                // rule [O]

function familyOf(name) {
  if (/NoSettle$/.test(name)) return 'nosettle-core';
  if (SETTLE_TIERS.has(name)) return 'settle-tier';
  if (name === '_changed' || name === '_fullChanged') return 'invalidation';   // the PRIVATE repaint verbs (invalidation-privacy standing rule) — settle-neutral by design
  if (CALLBACK.test(name)) return 'callback';
  if (IMMEDIATE_MUTATOR.test(name)) return 'immediate-mutator';
  if (DOUBLE_UNDERSCORE.test(name)) return 'leaf';
  if (LAYOUT_MACHINERY.test(name)) return 'layout-machinery';
  if (CONNECTOR.test(name)) return 'connector';
  if (DEFERRED_SETTLE.test(name)) return 'deferred-settle';
  return 'plain';                                                         // ordinary _ helper/query
}

// ---- stripLine + methodBoundary: copied verbatim from check-layering.js ----
function stripLine(line, state) {
  if (state) {
    const end = line.indexOf(state);
    if (end < 0) return { code: '', state };
    line = line.slice(end + state.length);
    state = null;
  }
  let out = '';
  let i = 0;
  while (i < line.length) {
    const three = line.substr(i, 3);
    if (three === '"""' || three === "'''") {
      const close = line.indexOf(three, i + 3);
      if (close < 0) { state = three; break; }
      i = close + 3; continue;
    }
    const c = line[i];
    if (c === '`') {
      const close = line.indexOf('`', i + 1);
      if (close < 0) { state = '`'; break; }
      i = close + 1; continue;
    }
    if (c === '"' || c === "'") {
      let j = i + 1;
      while (j < line.length) {
        if (line[j] === '\\') { j += 2; continue; }
        if (line[j] === c) break;
        j++;
      }
      i = j + 1; continue;
    }
    if (c === '#') break;
    out += c; i++;
  }
  return { code: out, state };
}

const MIXIN_CONTAINER = 'onceAddedClassProperties';
function methodBoundary(raw, mixinHashIndent) {
  const m = raw.match(METHOD_HEADER);
  if (m) return { method: m[1], mixinHashIndent: m[1] === MIXIN_CONTAINER ? -1 : null, kind: 'header' };
  if (mixinHashIndent !== null) {
    const sm = raw.match(MIXIN_METHOD_HEADER);
    if (sm) {
      const indent = sm[1].length;
      const lock = mixinHashIndent === -1 ? indent : mixinHashIndent;
      if (indent === lock) return { method: sm[2], mixinHashIndent: lock, kind: 'header' };
      return null;
    }
  }
  if (/^  [A-Za-z_]\w*:/.test(raw) || /^[^\s]/.test(raw)) return { method: null, mixinHashIndent: null, kind: 'end' };
  return null;
}
// ---- end copied machinery ----

function collectCoffee(dir, out) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) collectCoffee(p, out);
    else if (e.name.endsWith('.coffee')) out.push(p);
  }
  return out;
}

// Pass 1: every method def, with its body lines (code-stripped, with raw indent kept).
const defs = [];   // { klass, method, rel, line, body: [{n, code, indent}], settles, joins }
for (const file of collectCoffee(SRC, [])) {
  const rel = path.relative(path.join(__dirname, '..'), file);
  const klass = path.basename(file, '.coffee');
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  let cur = null, mixinHashIndent = null, strState = null;
  const flush = () => { if (cur) defs.push(cur); cur = null; };
  for (let n = 0; n < lines.length; n++) {
    const raw = lines[n];
    const { code, state } = stripLine(raw, strState);
    strState = state;
    if (strState === null) {
      const b = methodBoundary(raw, mixinHashIndent);
      if (b) {
        flush();
        mixinHashIndent = b.mixinHashIndent;
        if (b.kind === 'header') {
          cur = { klass, method: b.method, rel, line: n + 1, body: [], settles: false, joins: false };
          continue;
        }
      }
    }
    if (cur && code.trim()) {
      const indent = raw.match(/^\s*/)[0].length;
      cur.body.push({ n: n + 1, code, indent });
      if (SETTLE_CALL.test(code)) cur.settles = true;
      if (JOIN_CALL.test(code)) cur.joins = true;
    }
  }
  flush();
}

// Bucket A: *NoSettle-named defs that settle (the suffix lies).
const lying = defs.filter(d => /NoSettle$/.test(d.method) && (d.settles || d.joins));

// Bucket B: settling wrappers whose SETTLE CLOSURE calls a private non-family method.
// The closure = calls on the settle line AFTER the settle token, plus deeper-indented
// continuation lines until dedent (the `=>` body). DIRECT calls only, by doctrine (the [G]
// transitive-closure rejection: name-based reachability balloons and cannot model the guards).
// A private CALL, not a field read: the name must be applied — `(`-called, or CoffeeScript
// paren-less-called (followed by a space and an argument token). A bare `@_editing` in a
// condition (field read, no application) does not match either arm.
const PRIVATE_CALL = /[@.]\s*(_\w+)(?:\s*\(|[ \t]+(?!(?:then|and|or|is|isnt|not|if|unless|in|of)\b)(?=[@_$"'\[{A-Za-z0-9-]))/g;
const misNamedCores = [];   // { wrapper: def, callee, n }
for (const d of defs) {
  if (!d.settles && !d.joins) continue;
  if (SETTLE_TIERS.has(d.method)) continue;             // the tiers themselves are the flush
  for (let i = 0; i < d.body.length; i++) {
    const bl = d.body[i];
    const isSettleLine = SETTLE_CALL.test(bl.code) || JOIN_CALL.test(bl.code);
    if (!isSettleLine) continue;
    // calls on the settle line itself, past the settle token
    const tok = bl.code.match(/_settleLayoutsAfter\w*/);
    const after = bl.code.slice(tok.index + tok[0].length);
    const closureLines = [{ n: bl.n, code: after }];
    for (let j = i + 1; j < d.body.length && d.body[j].indent > bl.indent; j++) {
      closureLines.push({ n: d.body[j].n, code: d.body[j].code });
    }
    for (const cl of closureLines) {
      let m;
      PRIVATE_CALL.lastIndex = 0;
      while ((m = PRIVATE_CALL.exec(cl.code)) !== null) {
        const callee = m[1];
        const fam = familyOf(callee);
        if (fam !== 'plain') continue;                  // NoSettle core / recognized family — fine
        // a callee that is ITSELF a settling wrapper somewhere is a [G] matter, not a naming one
        if (defs.some(o => o.method === callee && (o.settles || o.joins))) continue;
        misNamedCores.push({ wrapper: d, callee, n: cl.n });
      }
    }
  }
}

// The context cross-tab: the whole _-prefixed surface by family × settles.
const privDefs = defs.filter(d => /^_/.test(d.method) || /NoSettle$/.test(d.method));
const tab = new Map();
for (const d of privDefs) {
  const fam = familyOf(d.method);
  const row = tab.get(fam) || { settling: 0, non: 0 };
  if (d.settles || d.joins) row.settling++; else row.non++;
  tab.set(fam, row);
}

console.log('census-nosettle-naming — Topic 3 (settle-tier-followups): non-settling private fns vs the *NoSettle suffix');
console.log(`  method defs scanned: ${defs.length} (${privDefs.length} private/_-prefixed or NoSettle-suffixed)`);
console.log('\n  the _-prefixed surface, family × settles:');
for (const [fam, row] of [...tab.entries()].sort((a, b) => (b[1].settling + b[1].non) - (a[1].settling + a[1].non))) {
  console.log(`    ${fam.padEnd(18)} settling=${String(row.settling).padStart(3)}  non-settling=${String(row.non).padStart(4)}`);
}
console.log(`\n  A) LYING SUFFIX (*NoSettle def that settles) — must be 0: ${lying.length}`);
for (const d of lying) console.log(`     ${d.klass}.${d.method}  — ${d.rel}:${d.line}`);
console.log(`\n  B) MIS-NAMED CORE (settle closure delegates to a plain _ method): ${misNamedCores.length}`);
for (const h of misNamedCores) console.log(`     ${h.wrapper.klass}.${h.wrapper.method} -> ${h.callee}  — ${h.wrapper.rel}:${h.n}`);
console.log('\n  (advisory census; plain non-settling _ helpers/queries keep their own names by design — Topic 3\'s refinement)');

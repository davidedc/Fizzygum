'use strict';
// lib/pointer-handlers.js — THE pointer-event handlers ActivePointerWdgt dispatches to widgets, and
// how each one is handed the pointer. ONE table, read by both gates that judge handler BODIES:
// check-raw-pointer-reads.js (a handler must not consume the raw screen pointer) and
// check-plane-discipline.js rule C (a handler's position parameter is already in the receiver's
// plane — or, for the one handler given the raw screen pointer, is not). Two hand lists of the same
// names drifted apart before (16 names in one, 8 in the other, each true only for its own gate).
//
// `pos` says what the dispatcher passes:
//   'plane'  — the FIRST parameter is the pointer mapped into the receiver's own plane;
//   'screen' — the parameter at index `screenPosParam` is the raw SCREEN pointer;
//   absent   — no position at all (the handler may still read the pointer, which is what the
//              raw-pointer gate looks for).
//
// ⭐ ASSERTED AGAINST THE DISPATCHER, both ways (dispatchProblems below, run by
// check-raw-pointer-reads.js on every build):
//   - every name here must occur in ActivePointerWdgt's code, so a renamed or retired handler fails
//     instead of leaving both gates scanning bodies nothing calls;
//   - every method the dispatcher HANDS A POINTER POSITION to must be here with a position, or in
//     POSITION_QUERIES (a question the hand asks a widget about a point, not an event it delivers),
//     so a new positional handler cannot slip past both gates. The shapes read are the dispatcher's
//     own: `x.m @_pointerPositionInPlaneOf …`, `x.m?(x.screenPointToMyPlane …)`, and the click
//     dispatch `w[expectedClick] @_pointerPositionInPlaneOf …` with `expectedClick = "<m>"`.
//   ⚠ Blind spot: a NEW handler dispatched with NO position (a hover-enter-shaped event) is not
//   found by any shape — add it here when you add the dispatch.
const fs = require('fs');
const path = require('path');
const { coffeeMask } = require('./coffee-mask');

const POINTER_HANDLERS = {
  pressBegan:           { pos: 'plane' },
  pressEnded:           { pos: 'plane' },
  pressCancelled:       {},
  activated:            { pos: 'plane' },
  contextMenuRequested: { pos: 'plane' },
  doubleActivated:      { pos: 'plane' },
  tripleActivated:      { pos: 'plane' },
  hoverMoved:           { pos: 'plane' },
  pressMoved:           { pos: 'plane' },
  hoverEntered:         {},
  hoverExited:          {},
  nonFloatDragging:     { pos: 'screen', screenPosParam: 1 },
  endOfNonFloatDrag:    {},
  scrolledBy:           {},
};

// Methods the dispatcher hands a pointer position that are QUERIES, not handlers, each with why.
const POSITION_QUERIES = {
  dockSideAt:    'a dock host is asked which edge band a point falls in, to arm a dock — no event is delivered',
  containsPoint: 'a hit test of a point against a widget\'s shape — no event is delivered',
};

const names = Object.keys(POINTER_HANDLERS);
const namesWith = (pos) => names.filter((n) => POINTER_HANDLERS[n].pos === pos);

// The problems with the table, read against ActivePointerWdgt's source (`srcRoot` = Fizzygum/src), each
// { kind, text } — the kind is the rule the reading gate fails on (PROBLEM_KINDS). [] when the two agree.
const PROBLEM_KINDS = ['TABLE_SOURCE_MISSING', 'TABLE_UNKNOWN_NAME', 'TABLE_UNLISTED_DISPATCH', 'TABLE_POS_MISMATCH',
  'TABLE_STALE_POSITION_QUERY', 'TABLE_UNMAPPED_PLANE_HANDLER'];
function dispatchProblems(srcRoot) {
  const file = path.join(srcRoot, 'ActivePointerWdgt.coffee');
  if (!fs.existsSync(file)) return [{ kind: 'TABLE_SOURCE_MISSING', text: 'ActivePointerWdgt.coffee not found at ' + file + ' — the handler table cannot be checked' }];
  const code = coffeeMask(fs.readFileSync(file, 'utf8'), file).map((l) => l.code);   // comments blanked, the dispatcher's strings kept
  const text = code.join('\n');
  const problems = [];
  for (const n of names) {
    if (!new RegExp('\\b' + n + '\\b').test(text)) {
      problems.push({ kind: 'TABLE_UNKNOWN_NAME', text: `'${n}' is in the handler table but ActivePointerWdgt never names it — a retired or renamed handler` });
    }
  }
  const positional = new Set();
  const MAPPED = /\.([A-Za-z_$][\w$]*)\??\s*\(?\s*(?:@_pointerPositionInPlaneOf|[@\w.]+\.screenPointToMyPlane\b)/g;
  let m;
  while ((m = MAPPED.exec(text)) !== null) positional.add(m[1]);
  if (/\[expectedClick\]\s*\(?\s*@_pointerPositionInPlaneOf/.test(text)) {
    const CLICK = /expectedClick\s*=\s*"([A-Za-z_$][\w$]*)"/g;
    while ((m = CLICK.exec(text)) !== null) positional.add(m[1]);
  }
  for (const n of positional) {
    if (POSITION_QUERIES[n]) continue;
    if (!POINTER_HANDLERS[n]) {
      problems.push({ kind: 'TABLE_UNLISTED_DISPATCH', text: `ActivePointerWdgt hands a pointer position to '${n}', which the handler table does not know — add it (or, if it is a query, to POSITION_QUERIES with why)` });
    } else if (POINTER_HANDLERS[n].pos !== 'plane') {
      problems.push({ kind: 'TABLE_POS_MISMATCH', text: `ActivePointerWdgt hands '${n}' a plane-mapped position, but the table says pos=${POINTER_HANDLERS[n].pos || 'none'}` });
    }
  }
  for (const q of Object.keys(POSITION_QUERIES)) {
    if (!positional.has(q)) problems.push({ kind: 'TABLE_STALE_POSITION_QUERY', text: `POSITION_QUERIES lists '${q}', which ActivePointerWdgt no longer hands a position — a stale entry` });
  }
  for (const n of namesWith('plane')) {
    if (!positional.has(n)) problems.push({ kind: 'TABLE_UNMAPPED_PLANE_HANDLER', text: `the table says '${n}' is handed a plane-mapped position, but no dispatch of it in ActivePointerWdgt passes one` });
  }
  return problems;
}

module.exports = {
  POINTER_HANDLERS,
  POSITION_QUERIES,
  HANDLER_NAMES: names,
  PLANE_POS_HANDLER_NAMES: namesWith('plane'),
  RAW_SCREEN_POS_HANDLERS: new Map(namesWith('screen').map((n) => [n, POINTER_HANDLERS[n].screenPosParam])),
  dispatchProblems,
  PROBLEM_KINDS,
};

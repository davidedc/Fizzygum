'use strict';
// lib/settling-setters.js — THE settling setters: the public GEOMETRY setters (Widget's) and TEXT setters
// (StringWdgt's) that each self-settle through the single-mutation tier `_settleLayoutsAfter`, so a layout
// pass or a `*NoSettle` core that reaches one re-enters the flush (the runtime flow-violation throw). READ
// from the two classes' own definitions, never spelled out, by every gate that recognises a settling
// setter by name: check-layering.js (rule [A]: low-level code must not call one; [C]: a geometry setter
// must not call another; [I]: a `__` leaf must not; [T]: a settling method must not also @-call one; and
// the [G] wrapper discovery, which leaves these names to [A]'s sharper message) and
// census-public-private-calls.js (a member call to one makes its caller SETTLING).
//
// WHY DERIVED. A hand list keeps matching the old names after a rename, and keeps a name nothing defines
// any more; a matcher that matches nothing reports nothing, so every rule built on it passes in silence.
// The list was also written twice (check-layering and the census), and two copies can disagree.
//
// THE RULES (each measured to reproduce the hand-kept list it replaces, name for name):
//   GEOMETRY — the public FACE of one of Widget's own `_apply<S>` corners: a Widget instance method named
//     `set<S>`, or for a movement corner the corner's own verb (`_applyMoveTo` -> `moveTo`), whose body
//     settles. Today: setBounds, moveTo, setExtent, setWidth, setHeight; `_applyMoveBy` and
//     `_applyGrantedBounds` have no public face. Widget's other settling setters — moveWithin (over its own
//     `_moveWithinNoSettle` core), setMaxDim, setRotationDegrees, setScaleFactor — face no apply corner,
//     so they are not here: the [G] wrapper discovery covers them as it covers any settling wrapper.
//   TEXT — a StringWdgt instance method named `set<X>` or `toggle<X>` whose body settles. Today: setFontName,
//     toggleWeight, toggleItalic, toggleIsPassword, setText, setFontSize. sizeToTextAndDisableFitting
//     settles too but sets no text property, so [G] covers it.
// "Settles" = a line of the body (the part after the header's arrow included) calls `@_settleLayoutsAfter`
// — the single-mutation tier, spelled as check-layering's SETTLE_CALL spells it (`\b` keeps the
// connector lane `_settleLayoutsAfterOrJoinEnclosingPass` out).
//
// THE SETTLE IS HELD ACROSS OVERRIDES. A gate reads a call by NAME, so the name must settle on every widget
// that answers it. An override of a derived setter in a subclass of its definer must settle itself or
// forward to `super`: SimpleTextWdgt and FizzytilesCodeWdgt override setText with `super theTextContent`,
// which settles through StringWdgt's. An override that does neither THROWS here — on that subtree the name
// the gates read as settling does not settle. (A same-named method on a class OUTSIDE the definer's
// subtree is a different method the name match cannot tell apart — SheetCellStyle's toggleWeight /
// toggleItalic / setFontName / setFontSize restyle a sheet cell — and is not held: every name match in
// these gates is receiver-blind. A mixin member is read as outside, since a mixin is in no `extends` chain.)
//
// ⚠ VACUITY GUARD. This THROWS — and a gate calling it then exits 2 naming the cause — when Widget.coffee or
// StringWdgt.coffee is missing, when a family's base setter is not derived (setExtent and moveTo, the extent
// and position faces the other geometry setters compose; setText, the text the other text setters style),
// or when an override drops the settle. Losing a base means the convention moved, and every rule keyed on
// these names needs a fresh look rather than a quieter list.
const fs = require('fs');
const path = require('path');
const { methodSpans } = require('./coffee-method-header');
const { stripComment } = require('./name-definitions');

const SETTLE_CALL = /[@.]\s*_settleLayoutsAfter\b/;
const SUPER_CALL = /\bsuper\b/;
const APPLY_CORNER = /^_apply([A-Z]\w*)$/;
const TEXT_SETTER_NAME = /^(set|toggle)[A-Z]/;
// hand-list-sanctioned: settlingSetters() throws when a base is not derived — check-layering.js and census-public-private-calls.js exit 2
const REQUIRED = { geometry: ['setExtent', 'moveTo'], text: ['setText'] };
const DEFINERS = { geometry: ['Widget', 'basic-widgets/Widget.coffee'], text: ['StringWdgt', 'basic-widgets/StringWdgt.coffee'] };

// A method span's body lines, comment-stripped: the inline body after the header's arrow, then the rest.
function bodyOf(lines, span) {
  const header = lines[span.line];
  const arrow = header.search(/[-=]>/);
  return [arrow >= 0 ? header.slice(arrow + 2) : ''].concat(lines.slice(span.line + 1, span.end)).map(stripComment);
}
const settles = (body) => body.some((l) => SETTLE_CALL.test(l));
// a class's own instance methods (not class-side, not a mixin member), name -> body
function ownMethods(lines) {
  const own = new Map();
  for (const s of methodSpans(lines)) if (!s.static && !s.mixin && !own.has(s.name)) own.set(s.name, bodyOf(lines, s));
  return own;
}
function readDefiner(srcRoot, family) {
  const file = path.join(srcRoot, DEFINERS[family][1]);
  if (!fs.existsSync(file)) {
    throw new Error(`settling-setters: ${file} not found — the ${family} setters are read from ${DEFINERS[family][0]}'s own definitions`);
  }
  return ownMethods(fs.readFileSync(file, 'utf8').split('\n'));
}
function walk(dir, acc) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (e.name.endsWith('.coffee')) acc.push(p);
  }
  return acc;
}

// { geometry: [...], text: [...] } — each family's names, longest first (so an alternation built from them
// reads the longest name first). `srcRoot` = Fizzygum/src.
function settlingSetters(srcRoot) {
  const widget = readDefiner(srcRoot, 'geometry');
  const geometry = new Set();
  for (const name of widget.keys()) {
    const corner = name.match(APPLY_CORNER);
    if (!corner) continue;
    const s = corner[1];
    for (const face of ['set' + s, s[0].toLowerCase() + s.slice(1)]) {
      if (widget.has(face) && settles(widget.get(face))) geometry.add(face);
    }
  }
  const string = readDefiner(srcRoot, 'text');
  const text = new Set([...string.keys()].filter((n) => TEXT_SETTER_NAME.test(n) && settles(string.get(n))));

  const problems = [];
  for (const [family, found] of [['geometry', geometry], ['text', text]]) {
    const missing = REQUIRED[family].filter((n) => !found.has(n));
    if (missing.length) problems.push(`the ${family} rule derives no ${missing.join(' / ')} from ${DEFINERS[family][0]}.coffee (found: [${[...found].join(', ') || 'none'}])`);
  }
  // the settle held across overrides: every definition of a derived name in a subclass of its definer
  const parentOf = new Map();
  const defsByName = new Map();   // name -> [{ klass, rel, line, body }]
  const derived = new Map([...geometry].map((n) => [n, DEFINERS.geometry[0]]).concat([...text].map((n) => [n, DEFINERS.text[0]])));
  for (const file of walk(srcRoot, [])) {
    const lines = fs.readFileSync(file, 'utf8').split('\n');
    for (const l of lines) {
      const ext = l.match(/^class\s+([A-Za-z_]\w*)\s+extends\s+([A-Za-z_]\w*)/);
      if (ext) parentOf.set(ext[1], ext[2]);
    }
    for (const s of methodSpans(lines)) {
      if (s.static || s.mixin || !derived.has(s.name)) continue;
      if (!defsByName.has(s.name)) defsByName.set(s.name, []);
      defsByName.get(s.name).push({ klass: path.basename(file, '.coffee'), rel: path.relative(srcRoot, file), line: s.line + 1, body: bodyOf(lines, s) });
    }
  }
  const descendsFrom = (klass, ancestor) => {
    const seen = new Set();
    for (let c = parentOf.get(klass); c && !seen.has(c); c = parentOf.get(c)) { if (c === ancestor) return true; seen.add(c); }
    return false;
  };
  for (const [name, definer] of derived) {
    for (const d of defsByName.get(name) || []) {
      if (d.klass === definer || !descendsFrom(d.klass, definer)) continue;
      if (!settles(d.body) && !d.body.some((l) => SUPER_CALL.test(l))) {
        problems.push(`${d.klass}.${name} (src/${d.rel}:${d.line}) overrides the settling ${definer}.${name} but neither settles nor calls super — on ${d.klass} the name the gates read as settling does not settle`);
      }
    }
  }
  if (problems.length) {
    throw new Error(`settling-setters: ${problems.join('; ')}. If the convention moved, update the rules in buildSystem/lib/settling-setters.js and re-read the gate rules that use it.`);
  }
  const order = (set) => [...set].sort((a, b) => b.length - a.length || a.localeCompare(b));
  return { geometry: order(geometry), text: order(text) };
}

module.exports = { settlingSetters };

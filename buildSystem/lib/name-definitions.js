'use strict';
// name-definitions.js — WHICH NAMES SOURCE LINES DEFINE: the one implementor harvest, shared by every
// gate that asks "does anything define this name?" — check-unresolved-sends.js (is a sent name
// implemented anywhere?) and check-part-edges.js (is an installed member defined anywhere outside the
// part that installs it?). One rule encoded twice drifts (lib/part-edge-scan.js's header lesson).
//
// A DEFINITION IS A CALLABLE — something a `[@.]name(` send can reach:
//   - a HEADER, `name:` or `@name:` at any indent (a class or class-side method, an object-literal or mixin member),
//     whose value is a function: an optional parameter list, read with a PAREN COUNTER (a default that holds a call,
//     `(w = @topWdgtUnderPointer()) ->`, does not end it) and then an arrow, the body on the same line or not; or a
//     signature wrapped right after its `(` (the one wrapped spelling every gate reads); or a header continued with a
//     trailing `\`;
//   - a prototype extension, `Number::toRadians = …`;
//   - an expando function, `Math.getRandomInt = (…) ->`, `swContextProto.foo = ->`;
//   - a TOP-LEVEL function, `swCanvasAnyTextDirty = ->` at column 0 (a boot global, sent as `window.x()`).
// A data key (`close: theme.barControlGlyphSize`) or an indented local (`width = (i) -> …` inside a method) is NOT
// one: no `[@.]name(` send reaches it, and counting one would keep a send resolved after every real method of its name
// is gone (a catch-all key form masks 48 sent names, measured). A property that HOLDS a closure is
// genuinely dynamic — check-unresolved-sends.js lists it in its allowlist, by name, with why.
// It still OVER-approximates where it reads: the comment strip is NAIVE (`stripComment` below) and keeps string
// literals, so a def-shaped line inside a heredoc BODY is harvested too — an extra definition can only make
// check-unresolved-sends resolve one more send and check-part-edges withdraw one more flag. The forms are
// LINE-ANCHORED: a def-shaped run in the MIDDLE of a line (`x = "  fake: ->"`) is not one. check-unresolved-sends.js's
// header explains the asymmetry with its call side. Its bite-proof deletes every callable definition of a name that
// still has a data key, and requires the send to fail (check-unresolved-sends-selftest.js).

// Cut at the first '#' that does NOT open a `#{…}` interpolation (the cut check-dead-methods.js makes
// too) — string literals are deliberately KEPT, see above.
function stripComment(line) {
  for (let k = line.indexOf('#'); k >= 0; k = line.indexOf('#', k + 1)) {
    if (line[k + 1] !== '{') return line.slice(0, k);
  }
  return line;
}

// Does a FUNCTION start at `i`: an optional parameter list (paren-counted, quotes skipped) and then an arrow?
function functionAt(line, i) {
  while (line[i] === ' ' || line[i] === '\t') i++;
  if (line[i] === '(') {
    let depth = 0, quote = null;
    for (; i < line.length; i++) {
      const c = line[i];
      if (quote) { if (c === '\\') i++; else if (c === quote) quote = null; continue; }
      if (c === '"' || c === "'") { quote = c; continue; }
      if (c === '(') depth++;
      else if (c === ')' && --depth === 0) { i++; break; }
    }
    if (depth !== 0) return false;
  }
  return /^\s*[-=]>/.test(line.slice(i));
}

// The callable forms (see the header), each { re, value }: `re` captures the defined name and ends where its value
// begins; `value` says what must start there — a function, a wrapped signature/continued header, or anything.
const DEF_FORMS = [
  { name: 'header',         re: /^\s*@?([A-Za-z_$][\w$]*)\s*:\s*/,            value: 'function-or-wrapped' },
  { name: 'prototype',      re: /^\s*[A-Za-z_$][\w$]*::([A-Za-z_$][\w$]*)\s*=/,  value: 'any' },
  { name: 'expando',        re: /^\s*[A-Za-z_$][\w$.]*\.([A-Za-z_$][\w$]*)\s*=/, value: 'function' },
  { name: 'top-level',      re: /^([A-Za-z_$][\w$]*)\s*=/,                     value: 'function' },
];

// The one name `line` (comment-stripped) defines, or undefined.
function definedName(line) {
  for (const f of DEF_FORMS) {
    const m = f.re.exec(line);
    if (!m) continue;
    const at = m.index + m[0].length;
    const rest = line.slice(at);
    if (f.value === 'any') return m[1];
    if (functionAt(line, at)) return m[1];
    if (f.value === 'function-or-wrapped' && /^(\(|\\)\s*$/.test(rest)) return m[1];   // `name: (` wrapped, `name: \` continued
  }
  return undefined;
}

// The names `lines` define, added to `into` (a fresh Set by default), which is returned.
function harvestDefs(lines, into = new Set()) {
  for (const raw of lines) {
    const name = definedName(stripComment(raw));
    if (name !== undefined) into.add(name);
  }
  return into;
}

module.exports = { stripComment, DEF_FORMS, definedName, harvestDefs };

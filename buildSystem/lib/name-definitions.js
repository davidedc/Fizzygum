'use strict';
// name-definitions.js — WHICH NAMES SOURCE LINES DEFINE: the one implementor harvest, shared by every
// gate that asks "does anything define this name?" — check-unresolved-sends.js (is a sent name
// implemented anywhere?) and check-part-edges.js (is an installed member defined anywhere outside the
// part that installs it?). One rule encoded twice drifts (lib/part-edge-scan.js's header lesson).
//
// It OVER-approximates on purpose, and both consumers rely on that direction: an extra "definition"
// can only make check-unresolved-sends resolve one more send and check-part-edges withdraw one more
// flag — never raise a flag either gate would not otherwise raise. Hence:
//   - the comment strip is NAIVE (`stripComment` below): it keeps string literals, so a def-shaped
//     line inside a heredoc BODY is harvested too;
//   - the last DEF_FORM counts ANY `name:` / `name =` key, because a property may hold a closure.
// The forms are LINE-ANCHORED: a def-shaped run in the MIDDLE of a line (`x = "  fake: ->"`) is not
// one. check-unresolved-sends.js's header explains the asymmetry with its call side.

// Cut at the first '#' that does NOT open a `#{…}` interpolation (the cut check-dead-methods.js makes
// too) — string literals are deliberately KEPT, see above.
function stripComment(line) {
  for (let k = line.indexOf('#'); k >= 0; k = line.indexOf('#', k + 1)) {
    if (line[k + 1] !== '{') return line.slice(0, k);
  }
  return line;
}

// Every shape that can put a callable name into the world. The 2-space class-body form is the
// canonical HEADER every other gate keys off; the rest are the forms the 2026-07-15 probe proved it
// needs (each false positive it reported was one of these, not a real bug).
const DEF_FORMS = [
  /^  ([A-Za-z_$][\w$]*)\s*:\s*(\([^)]*\)\s*)?[-=]>/,                          // 2-space class-body method  (the canonical HEADER)
  /^\s*([A-Za-z_$][\w$]*)\s*:\s*(\([^)]*\)\s*)?[-=]>/,                         // any-indent object-literal / mixin-DSL member fn
  /^\s*[A-Za-z_$][\w$]*::([A-Za-z_$][\w$]*)\s*=/,                              // prototype extension        (Number::toRadians = ->)
  /^\s*[A-Za-z_$][\w$.]*\.([A-Za-z_$][\w$]*)\s*=\s*(\([^)]*\)\s*)?[-=]>/,      // static / expando fn        (Math.getRandomInt = …, swContextProto.foo = …)
  /^\s*([A-Za-z_$][\w$]*)\s*=\s*(\([^)]*\)\s*)?[-=]>/,                         // bare local fn              (helper = ->)
  /^\s*@?([A-Za-z_$][\w$]*)\s*[:=]/,                                           // ANY other property key — over-approximate ON PURPOSE (a property may hold a closure)
];

// The names `lines` define, added to `into` (a fresh Set by default), which is returned.
function harvestDefs(lines, into = new Set()) {
  for (const raw of lines) {
    const line = stripComment(raw);
    for (const re of DEF_FORMS) {
      const m = re.exec(line);
      if (m) into.add(m[1]);
    }
  }
  return into;
}

module.exports = { stripComment, DEF_FORMS, harvestDefs };

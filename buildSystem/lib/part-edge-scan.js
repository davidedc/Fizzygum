'use strict';
/*
 * part-edge-scan.js — THE guard/await classifier, in ONE place.
 *
 * Extracted from check-part-edges.js so that anything else asking "would this reference be allowed?"
 * asks the GATE'S OWN rules rather than a copy of them. A hypothetical-part analyser had already
 * grown a copy-pasted duplicate, which is exactly the shape that produced four bugs of one kind in
 * arc 4: one rule, encoded twice, drifting.
 *
 * `guardedPartsPerLine(lines, ownerOfClass, parts, ownerOfMember)` returns, for each line, the SET OF
 * PARTS whose classes (and installed members) may be named there. All its sources are scope-opening
 * rather than line-local:
 *   - an `X?` existence test (its own line, plus everything indented under it, plus a multi-line
 *     boolean continuation);
 *   - a `return unless X?` / `return if !X?` bail-out, which covers the rest of the method;
 *   - `whenAllLoaded ["a", "b"], ->`, which opens a scope exactly as a guard does — an AWAIT IS A
 *     GUARD, and it is the idiom a lazy part is supposed to use. ⚠ whenOptionalPartsLoaded is
 *     deliberately NOT one: it runs its callback even when the part never arrived;
 *   - with `ownerOfMember` (member name -> the part that alone provides it, see check-part-edges.js),
 *     an existence test on such a MEMBER — `@m?()`, `x.m? arg`, `if x.m?`, `return unless x.m?` —
 *     in exactly the shapes an `X?` takes. A part is all-or-nothing, so a member that only that part
 *     provides being here proves the whole part is here, just as one of its classes would. Omitting
 *     the argument leaves every other caller's answer exactly what it was.
 * `codePartOf(line)` strips comments and string literals: prose may name any class, and a class
 * NAME as data is the sanctioned indirection for a lazy part. `stringLiteralsOf(line)` is its
 * complement — the contents of the line's string literals, comments excluded — for a scan that has to
 * read a name used AS data (a member dispatched by name).
 */

function codePartOf(line) {
  let out = '';
  let quote = null;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (quote) {
      if (c === '\\') { i++; continue; }
      if (c === quote) quote = null;
      continue;                     // characters inside a string are not code identifiers here
    }
    if (c === '"' || c === "'") { quote = c; continue; }
    if (c === '#') break;           // rest of the line is a comment
    out += c;
  }
  return out;
}

// The contents of every single-line string literal on the line, read with codePartOf's own lexing (so
// the two always agree on where a string starts and ends) and stopping at a comment.
function stringLiteralsOf(line) {
  const out = [];
  let quote = null;
  let cur = '';
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (quote) {
      if (c === '\\') { cur += c + (line[i + 1] || ''); i++; continue; }
      if (c === quote) { out.push(cur); quote = null; cur = ''; continue; }
      cur += c;
      continue;
    }
    if (c === '"' || c === "'") { quote = c; continue; }
    if (c === '#') break;
  }
  return out;
}

// An existence test on a member: `@m?`, `x.m?` (a soak call, a soak access or a plain test).
const MEMBER_EXISTENCE_TEST = /[@.]([A-Za-z_$][\w$]*)\?/g;

const indentOf = (line) => line.length - line.replace(/^\s*/, '').length;

// Which PARTS are guarded on each line. Two sources, both per-part (see the header):
//   * an `X?` existence test (or an `[@.]m?` one on a member in ownerOfMember), guarding its own
//     line plus every deeper-indented line under it (the guarded block AND the multi-line boolean
//     continuation);
//   * a `return unless X?` bail-out (or `return unless x.m?`), guarding the rest of the enclosing
//     method.
// A logical line can span several physical ones: CoffeeScript continues it when the previous line
// ends with a binary/opening operator, and the continuation may be indented LESS than the opener
// (StringWdgt.toString does exactly that). So a continuation inherits its opener's guards outright,
// independently of indentation.
const CONTINUES = /(?:\b(?:and|or|not|is|isnt|then|else|unless|if|in|of)|&&|\|\||[,+\-*/%=<>?:.([{])\s*$/;

function guardedPartsPerLine(lines, ownerOfClass, parts, ownerOfMember) {
  const perLine = lines.map(() => new Set());
  const openGuards = [];      // {indent, part} — active while we are deeper than indent
  let method = null;          // {indent, parts:Set} — a return-unless bail-out's scope
  let prevCodeLine = -1;      // last non-blank line, for continuation detection

  for (let i = 0; i < lines.length; i++) {
    const raw = lines[i];
    const ind = indentOf(raw);
    const blank = raw.trim() === '';
    const isContinuation = prevCodeLine >= 0 && CONTINUES.test(codePartOf(lines[prevCodeLine]));

    if (!blank && !isContinuation) {
      while (openGuards.length && ind <= openGuards[openGuards.length - 1].indent) openGuards.pop();
      if (method && ind <= method.indent) method = null;
    }

    // guards inherited from an enclosing `if X?` / continuation, and from a method bail-out
    for (const g of openGuards) perLine[i].add(g.part);
    if (method) for (const p of method.parts) perLine[i].add(p);
    // a continuation carries its opener's guards, whatever its indentation
    if (!blank && isContinuation) for (const p of perLine[prevCodeLine]) perLine[i].add(p);

    if (blank) continue;
    prevCodeLine = i;

    const m = /^(\s+)(?:@)?[\w$]+\s*:\s*(?:\(.*?\))?\s*[-=]>/.exec(raw);
    if (m) method = { indent: m[1].length, parts: new Set() };

    // `return unless X?` / `return if !X?` -> guards the rest of the method
    const bail = /^\s*return\b.*?\b([A-Z][\w$]*)\?/.exec(raw);
    if (bail && /\breturn\s+(?:unless|if\s*!)/.test(raw)) {
      const part = ownerOfClass.get(bail[1]);
      if (part && method) { method.parts.add(part); perLine[i].add(part); }
    }

    // any `X?` existence test on this line guards this line and everything nested under it
    const tests = raw.match(/\b[A-Z][\w$]*\?/g) || [];
    for (const t of tests) {
      const part = ownerOfClass.get(t.slice(0, -1));
      if (!part) continue;
      perLine[i].add(part);
      openGuards.push({ indent: ind, part });
    }

    // ...and so does an existence test on a member only one part provides, read off the CODE (a
    // member named in prose or as a string tests nothing), bail-out included
    if (ownerOfMember) {
      const code = codePartOf(raw);
      const bails = /^\s*return\s+(?:unless|if\s*!)/.test(code);
      let t;
      MEMBER_EXISTENCE_TEST.lastIndex = 0;
      while ((t = MEMBER_EXISTENCE_TEST.exec(code)) !== null) {
        const part = ownerOfMember.get(t[1]);
        if (!part) continue;
        perLine[i].add(part);
        openGuards.push({ indent: ind, part });
        if (bails && method) method.parts.add(part);
      }
    }

    // AN AWAIT IS A GUARD TOO, and not seeing that was this gate's blind spot: a lazy part's
    // prescribed entry point is `world.parts.whenAllLoaded ["maps", "plots"], ->`, and every line
    // nested under it runs with those parts present -- exactly the scope an `if X?` opens. Before
    // this, the gate demanded a guard at sites that had correctly awaited, which pushes authors
    // toward `if X?` -- the one idiom that is WRONG for a lazy part, because it silently swallows
    // the click instead of fetching. Only whenAllLoaded counts: whenOptionalPartsLoaded runs its
    // callback even when the part never arrives, so a reference under it still needs its own guard.
    const awaited = /\bwhenAllLoaded\s*\[([^\]]*)\]/.exec(raw);
    if (awaited) {
      for (const m of awaited[1].match(/["']([^"']+)["']/g) || []) {
        const part = m.slice(1, -1);
        if (!parts[part]) continue;
        perLine[i].add(part);
        openGuards.push({ indent: ind, part });
      }
    }
  }
  return perLine;
}

module.exports = { codePartOf, stringLiteralsOf, indentOf, guardedPartsPerLine };

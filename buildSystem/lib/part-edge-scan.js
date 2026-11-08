'use strict';
/*
 * part-edge-scan.js — THE guard/await classifier, in ONE place.
 *
 * Extracted from check-part-edges.js so that anything else asking "would this reference be allowed?"
 * asks the GATE'S OWN rules rather than a copy of them. A hypothetical-part analyser had already
 * grown a copy-pasted duplicate, which is exactly the shape that produced four bugs of one kind in
 * arc 4: one rule, encoded twice, drifting.
 *
 * `guardedPartsPerLine(masked, ownerOfClass, parts, ownerOfMember)` returns, for each line of a text read
 * through lib/coffee-mask.js (`masked`), the SET OF PARTS whose classes (and installed members) may be named
 * there. A guard is read off the line's bare code, so a `X?` in a comment or a string guards nothing; a line
 * holding only a comment is blank to it, and a line inside a multi-line literal belongs to the line that
 * opened it. All its sources are scope-opening rather than line-local:
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
 * `declaredRequires(parts, partName)` is the parts.json half of the same question: which other parts
 * a part's `requires` lets it name unguarded (one level, and only what has ARRIVED when it runs).
 * A reference is read off a line's bare code (lib/coffee-mask.js): prose may name any class, and a class
 * NAME as data is the sanctioned indirection for a lazy part. `stringLiteralsOf(record)` is its
 * complement — the contents of the line's literals, comments excluded — for a scan that has to
 * read a name used AS data (a member dispatched by name).
 */

// The contents of each literal on a line (a record of lib/coffee-mask.js): every run of literal text with its
// quotes taken off. An interpolation's code splits its string into the runs around it.
function stringLiteralsOf({ code, mask }) {
  const out = [];
  for (let k = 0; k < code.length; k++) {
    if (mask[k] !== 'str') continue;
    let j = k;
    while (j < code.length && mask[j] === 'str') j++;
    out.push(code.slice(k, j).replace(/^["'`]+|["'`]+$/g, ''));
    k = j - 1;
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
// A return that only happens unless/if-not something — `return unless X?`, `return undefined if !x.m?` — and where its
// condition starts (just past the `unless` / `if !`), or -1: only an existence test in the CONDITION guards what follows
// (`return Lazy? unless ready` guards nothing).
const BAIL_OUT = /^\s*return\b.*?\b(?:unless\b|if\s*!)/;
const bailConditionAt = (code) => { const m = BAIL_OUT.exec(code); return m ? m[0].length : -1; };
// A `?` continues only as the binary existential, written spaced (`a ?`): a line ending in `X?` ends in an
// existence test (`foo() if Bar?`), which the lexer reads as finished.
const CONTINUES = /(?:\b(?:and|or|not|is|isnt|then|else|unless|if|in|of)|&&|\|\||\s\?|[,+\-*/%=<>:.([{])\s*$/;

function guardedPartsPerLine(masked, ownerOfClass, parts, ownerOfMember) {
  const perLine = masked.map(() => new Set());
  const openGuards = [];      // {indent, part} — active while we are deeper than indent
  let method = null;          // {indent, parts:Set} — a return-unless bail-out's scope
  let prevCodeLine = -1;      // last line holding code, for continuation detection

  for (let i = 0; i < masked.length; i++) {
    const { bare: code, code: withLiterals } = masked[i];
    if (masked[i].continuesLiteral) {             // inside a multi-line literal: the opener's line goes on
      if (prevCodeLine >= 0) for (const p of perLine[prevCodeLine]) perLine[i].add(p);
      continue;
    }
    const ind = indentOf(code);
    const blank = code.trim() === '';
    const isContinuation = prevCodeLine >= 0 && CONTINUES.test(masked[prevCodeLine].bare);

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

    const m = /^(\s+)(?:@)?[\w$]+\s*:\s*(?:\(.*?\))?\s*[-=]>/.exec(code);
    if (m) method = { indent: m[1].length, parts: new Set() };

    // `return unless X?` / `return if !X?` -> guards the rest of the method (so does `return <value> unless X?`)
    const bailAt = bailConditionAt(code);
    const bail = bailAt >= 0 && /\b([A-Z][\w$]*)\?/.exec(code.slice(bailAt));
    if (bail) {
      const part = ownerOfClass.get(bail[1]);
      if (part && method) { method.parts.add(part); perLine[i].add(part); }
    }

    // any `X?` existence test on this line guards this line and everything nested under it
    const tests = code.match(/\b[A-Z][\w$]*\?/g) || [];
    for (const t of tests) {
      const part = ownerOfClass.get(t.slice(0, -1));
      if (!part) continue;
      perLine[i].add(part);
      openGuards.push({ indent: ind, part });
    }

    // ...and so does an existence test on a member only one part provides (a member named in prose or as
    // a string tests nothing), bail-out included
    if (ownerOfMember) {
      let t;
      MEMBER_EXISTENCE_TEST.lastIndex = 0;
      while ((t = MEMBER_EXISTENCE_TEST.exec(code)) !== null) {
        const part = ownerOfMember.get(t[1]);
        if (!part) continue;
        perLine[i].add(part);
        openGuards.push({ indent: ind, part });
        if (bailAt >= 0 && t.index >= bailAt && method) method.parts.add(part);
      }
    }

    // AN AWAIT IS A GUARD TOO, and not seeing that was this gate's blind spot: a lazy part's
    // prescribed entry point is `world.parts.whenAllLoaded ["maps", "plots"], ->`, and every line
    // nested under it runs with those parts present -- exactly the scope an `if X?` opens. Before
    // this, the gate demanded a guard at sites that had correctly awaited, which pushes authors
    // toward `if X?` -- the one idiom that is WRONG for a lazy part, because it silently swallows
    // the click instead of fetching. Only whenAllLoaded counts: whenOptionalPartsLoaded runs its
    // callback even when the part never arrives, so a reference under it still needs its own guard.
    const awaited = /\bwhenAllLoaded\s*\[([^\]]*)\]/.exec(withLiterals);   // its part names are strings
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

const isLazyPart = (parts, partName) => partName !== 'core' && !!parts[partName] && parts[partName].eager === false;

// What a part may name without guarding: itself, plus the `requires` entries that actually cover
// the reference. ⚠⚠ `requires` MEANS TWO DIFFERENT THINGS AND ONLY ONE OF THEM IS ENOUGH HERE:
// it always promises the other part SHIPS (buildProfile.py refuses a profile missing it), but it
// promises the classes have ARRIVED only when the OWNER is lazy -- there PartsRegistry brings the
// requirements fully in before ingesting this part. An EAGER owner is running from the first frame,
// so a LAZY requirement may not be here yet and that site still needs a guard or an await where it
// stands. An eager->EAGER requirement is fine: both are in the artifact from frame one, and
// shipping-together is the whole of what could go wrong.
// ⚠ ONE LEVEL, NOT THE CLOSURE: `dev-tools` requires `demos` requires `authoring` would not let a
// lazy owner reach `authoring` through `demos`, because the gate reads the array, not its fixpoint.
// ⚠ Do not "simplify" the eager discount away: without it an eager part declaring `requires` on a
// lazy one could both reference and `extends` its classes with the build green (planted against
// the lazy 'app-kit' from 'dev-tools': 0 violations), and an analyser asking this question
// (what-pins-core.js) called a move free that the gate fails.
function declaredRequires(parts, partName) {
  const required = ((parts[partName] || {}).requires) || [];
  const ownerIsLazy = isLazyPart(parts, partName);
  return new Set([partName, ...required.filter(r => ownerIsLazy || !isLazyPart(parts, r))]);
}

module.exports = { stringLiteralsOf, indentOf, guardedPartsPerLine, isLazyPart, declaredRequires };

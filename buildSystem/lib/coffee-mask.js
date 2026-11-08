// coffee-mask.js — what each character of a CoffeeScript TEXT is (code, a literal's text, or a comment), as the
// CoffeeScript lexer reads it. The ONE reading of CoffeeScript-as-code for every gate and census that has one.
//
// coffeeMask(text, where) -> one record per line of `text` (split on '\n'), each { mask, code, bare, comment,
// continuesLiteral }:
//   mask     per character, 'code' | 'str' | 'lit' | 'cut'. 'str' is a string's or a heredoc's text, its quotes
//            included; 'lit' is the text of any other literal — a regex or heregex (its flags included), a `…` JS
//            passthrough. The code inside an interpolation (`#{…}`) is 'code', and so is everything between its
//            braces. 'cut' is a comment: a `#` to the end of its line, a `###` block, a heregex's `# …`.
//   code     the line with its comments blanked: what a reader that keeps literals reads (a name dispatched by a
//            string, a colour in a string, CoffeeScript in a heredoc).
//   bare     the line with its comments and every literal's contents blanked, each literal's delimiters and an
//            interpolation's code kept: what a reader of code alone reads. `f "x", 1` reads `f " ", 1`, so a call
//            given a literal still reads as a call given an argument.
//   comment  the line's comment text from its first comment character, or undefined when it has none.
//   continuesLiteral  whether the line starts inside a literal an earlier line opened (a heredoc's body and its
//            closing line, a string spanning lines): a reader looking for a class-body key or a method boundary
//            skips it.
// Every view keeps every column, so a column found in one is that column of the line. isCommentOnly(record) says
// whether the line holds a comment and nothing else.
//
// The reading is the lexer's own (CoffeeScript.tokens, from lib/meta-compiler.js's bundledCoffeeScript: the compiler
// the page runs), so a `#` or a quote inside a regex, a heregex holding `'''`, a string spanning lines, a `#` in a
// heredoc and a comment inside a multi-line interpolation all read as they compile. Outside a literal a `#` can only
// open a comment, so the comments are the `#`s no literal holds — and, inside a heregex, a `#` after whitespace, which
// the compiler drops as a comment. The lexer drops a leading BOM and every \r; both are laid back, so the columns are
// the text's. A text the lexer refuses is refused, COFFEE_MASK_UNLEXABLE <where>:<line>, never read by a guess.
//
// A process lexes a text once: the records are kept by the text they read, so readers sharing a file share its
// reading. They are read-only — no reader may change one.
//
// A heredoc holding CoffeeScript (a tool's source, a Macro verb) is a literal here like any string: a reader that
// treats one as code passes that heredoc's text to coffeeMask as a text of its own.
//
// Readers: every gate and census that reads CoffeeScript as code (docs/architecture/lint-and-static-checks.md §6c),
// and lib/tests-repo-code.js for the tests repo's harness and macro sources. Cases: lib/coffee-mask-selftest.js.

const { bundledCoffeeScript } = require('./meta-compiler');

let CoffeeScript;                                              // loaded on first use
const GROUP_END = { STRING_START: 'STRING_END', REGEX_START: 'REGEX_END' };   // a literal holding interpolations
const KIND = { STRING_START: 'str', REGEX_START: 'lit', STRING: 'str', REGEX: 'lit', JS: 'lit' };
const LAYOUT = new Set(['TERMINATOR', 'INDENT', 'OUTDENT']);   // tokens no character is
const readings = new Map();                                    // text -> its records

function coffeeMask(text, where = 'a text') {
  if (!readings.has(text)) readings.set(text, read(text, where));
  return readings.get(text);
}

function read(text, where) {
  CoffeeScript = CoffeeScript || bundledCoffeeScript();
  const bom = text.charCodeAt(0) === 0xFEFF ? 1 : 0;
  const lexed = text.slice(bom).replace(/\r/g, ' ');           // what the lexer reads, column for column (\r as a space)
  let tokens;
  try { tokens = CoffeeScript.tokens(lexed); } catch (e) {
    const line = e.location ? e.location.first_line + 1 : '?';
    throw new Error(`COFFEE_MASK_UNLEXABLE ${where}:${line} — ${String(e.message).split('\n')[0]}`);
  }
  const starts = [0];
  for (let k = 0; k < lexed.length; k++) if (lexed[k] === '\n') starts.push(k + 1);
  const span = (t) => [starts[t[2].first_line] + t[2].first_column, starts[t[2].last_line] + t[2].last_column];

  // The literals and the interpolations inside them, read off the token stream. A literal with interpolations is a
  // group (STRING_START … STRING_END, REGEX_START … REGEX_END) whose own tokens are its text and the lexer's
  // scaffolding around each `#{…}`: a `(` on the `{`, a `)` on the `}`. Between those two is code again — and a
  // literal there is a literal of its own. Each is painted at its nesting depth, outermost first, so an inner paint
  // wins: a literal at nesting level L at depth 2L, the code of an interpolation inside it at 2L + 1.
  const paints = [];                                           // { from, to, kind: 'str'|'lit'|'code', depth }
  const groups = [];                                           // open groups: { end, kind, from, interpolating, codeFrom }
  for (const t of tokens) {
    if (t.generated || LAYOUT.has(t[0])) continue;
    const [a, b] = span(t);
    const top = groups[groups.length - 1];
    const level = groups.length - 1;                           // the top group's own nesting level
    if (top && top.interpolating === 0) {                      // a token of the group's text, not of its code
      if (t[0] === top.end) { paints.push({ from: top.from, to: b, kind: top.kind, depth: 2 * level }); groups.pop(); }
      else if (t[0] === '(' && lexed[a] === '{') { top.interpolating = 1; top.codeFrom = a + 1; }
      continue;
    }
    if (top && t[0] === ')' && lexed[a] === '}' && top.interpolating === 1) {
      top.interpolating = 0;
      paints.push({ from: top.codeFrom, to: a - 1, kind: 'code', depth: 2 * level + 1 });
      continue;
    }
    if (top && t[0] === '(' && lexed[a] === '(') top.interpolating++;
    if (top && t[0] === ')' && lexed[a] === ')') top.interpolating--;
    if (GROUP_END[t[0]]) groups.push({ end: GROUP_END[t[0]], kind: KIND[t[0]], from: a, interpolating: 0 });
    else if (KIND[t[0]]) paints.push({ from: a, to: b, kind: KIND[t[0]], depth: 2 * groups.length });
  }

  const cls = new Array(lexed.length).fill('code');
  const delimiter = new Uint8Array(lexed.length);              // a literal's own delimiter: kept in `bare`
  paints.sort((p, q) => p.depth - q.depth);
  for (const { from: a, to: b, kind } of paints) {
    for (let k = a; k <= b; k++) cls[k] = kind;
    if (kind === 'code') continue;
    const open = /^("""|'''|\/\/\/|```)/.test(lexed.slice(a, a + 3)) ? 3 : 1;
    let close = b;
    if (lexed[a] === '/') while (close > a && /[a-z]/.test(lexed[close])) close--;   // a regex's flags follow it
    for (let k = a; k < a + open; k++) delimiter[k] = 1;
    for (let k = close; k > close - open && k > a; k--) delimiter[k] = 1;
    // a heregex's comments: a `#` after whitespace (not a `#{`) runs to the end of its line, and the compiler drops it
    if (open === 3 && lexed[a] === '/') {
      for (let k = a + 3; k < close - 2; k++) {
        if (lexed[k] !== '#' || cls[k] !== 'lit' || lexed[k + 1] === '{' || !/\s/.test(lexed[k - 1])) continue;
        while (k < close - 2 && lexed[k] !== '\n') cls[k++] = 'cut';
      }
    }
  }
  for (let k = 0; k < lexed.length; k++) {
    if (lexed[k] !== '#' || cls[k] !== 'code') continue;
    let end;
    if (lexed.startsWith('###', k) && !lexed.startsWith('####', k)) {
      end = lexed.indexOf('###', k + 3);
      end = end < 0 ? lexed.length : end + 3;
    } else {
      end = lexed.indexOf('\n', k);
      if (end < 0) end = lexed.length;
    }
    for (let j = k; j < end; j++) if (lexed[j] !== '\n') cls[j] = 'cut';
    k = end - 1;
  }

  return text.split('\n').map((line, i) => {
    const mask = [], keep = [];
    for (let k = 0; k < line.length; k++) {
      const at = starts[i] + k - (i === 0 ? bom : 0);              // the BOM, only ever on line 0, is code
      mask.push(at < 0 ? 'code' : cls[at]);
      keep.push(at >= 0 && delimiter[at] === 1);
    }
    let codeView = '', bare = '', firstCut = -1;
    for (let k = 0; k < line.length; k++) {
      const c = line[k], m = mask[k];
      if (m === 'cut' && firstCut < 0) firstCut = k;
      codeView += m === 'cut' ? ' ' : c;
      bare += m === 'code' || keep[k] ? c : ' ';
    }
    const before = cls[starts[i] - 1];                         // the newline ending the line above, if any
    return { mask, code: codeView, bare, comment: firstCut < 0 ? undefined : line.slice(firstCut),
             continuesLiteral: i > 0 && (before === 'str' || before === 'lit') };
  });
}

// A line holding a comment and nothing else (a `#` line, a line of a `###` block): where a gate's sanction marker
// for the code below it is written.
const isCommentOnly = (line) => line.comment !== undefined && line.code.trim() === '';

module.exports = { coffeeMask, isCommentOnly };

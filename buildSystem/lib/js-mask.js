// js-mask.js — label each character of a JavaScript source as code, string or comment: the JS twin of
// lib/coffee-mask.js, for a reader that must cut comments and keep strings.
//
// maskJs(text) -> { mask, templates }
//   mask[i] is 'code', 'str' (a quoted string, a template literal's text, a regex literal) or 'cut' (a
//   `//` or `/* … */` comment, or a `#!` first line).
//   templates lists every template literal as { start, end, depth }: its TEXT between the backticks
//   (start inclusive, end exclusive), depth 0 for one written in code, 1+ for one nested inside a `${…}`.
//
// One left-to-right pass over the whole text, so a comment is cut wherever it starts (trailing ones too),
// a comment marker inside a string or a template is text, and a backtick inside a comment opens nothing.
// A `${…}` inside a template is code, braces counted, templates nested to any depth.
//
// A `/` that is not a comment opens a REGEX LITERAL when the previous significant token cannot end a value:
// the start of the text, an operator or opening punctuation, or a keyword that takes an expression
// (`return`, `typeof`, …). After a name, a number, `)` or `]` it divides.
//
// Stated limits:
//   - A regex literal right after a VALUE token — a name, a number, `)`, `]` — reads as a division
//     (`if (x) /re/.test(s)`, or after a keyword used as a property name, `a.return /re/`). Its text then reads
//     as code, and should it hold `/*`, a block comment opens there and runs to the next `*/`, CUTTING code,
//     possibly across lines. Measured absent (2026-11-06): no comment-span disagreement with js-tokens (below)
//     or with acorn 7.4 over the same files.
//   - `}` is taken to end a BLOCK, and a postfix `++`/`--` is an operator, so a `/` right after either opens a
//     regex. Where it really divides (after an object literal's `}`, after `x++`), the text up to the next `/` on
//     the line reads as a string: it cuts nothing, and it cannot pass the line, as a regex literal holds no
//     newline.
// Verified character by character against js-tokens 4.0.0 (2026-11-06; probe Fizzygum-tests/.scratch/
// tests-repo-readers/js-mask-vs-js-tokens.js) over Fizzygum-tests' scripts/ and macro command files: 462 files,
// 3.3 M characters. Every macro file's template spans agree. Every comment span agrees but two, and both are
// js-tokens misreading a division followed by a trailing comment (`n / 8));  // …`) as a regex literal: it
// decides a regex by what FOLLOWS the `/`, never by what precedes it. There this mask is right.
//
// Reader: lib/tests-repo-code.js.

const KEYWORDS_BEFORE_EXPRESSION = new Set(['return', 'typeof', 'instanceof', 'in', 'of', 'new', 'delete', 'void',
  'throw', 'case', 'do', 'else', 'yield', 'await']);

function maskJs(text) {
  const n = text.length;
  const mask = new Array(n).fill('code');
  const templates = [];
  const frames = [];        // open template literals, innermost last: { start, inExpr, braces }
  let valueBefore = false;  // does the previous significant token end a value (so a `/` divides)?
  const mark = (a, b, kind) => { for (let k = a; k < b && k < n; k++) mask[k] = kind; };
  let i = 0;
  if (text.startsWith('#!')) { i = text.indexOf('\n'); if (i < 0) i = n; mark(0, i, 'cut'); }
  while (i < n) {
    const top = frames[frames.length - 1];
    const c = text[i];
    if (top && !top.inExpr) {                       // a template literal's text
      if (c === '\\') { mark(i, i + 2, 'str'); i += 2; continue; }
      if (c === '`') {
        templates.push({ start: top.start, end: i, depth: frames.length - 1 });
        mask[i] = 'str'; frames.pop(); i++; valueBefore = true; continue;
      }
      if (c === '$' && text[i + 1] === '{') { mark(i, i + 2, 'str'); top.inExpr = true; top.braces = 0; i += 2; valueBefore = false; continue; }
      mask[i] = 'str'; i++; continue;
    }
    const d = text[i + 1];
    if (c === ' ' || c === '\t' || c === '\n' || c === '\r') { i++; continue; }
    if (c === '/' && d === '/') { let j = text.indexOf('\n', i); if (j < 0) j = n; mark(i, j, 'cut'); i = j; continue; }
    if (c === '/' && d === '*') { let j = text.indexOf('*/', i + 2); j = j < 0 ? n : j + 2; mark(i, j, 'cut'); i = j; continue; }
    if (c === '"' || c === "'") {
      let j = i + 1;
      while (j < n && text[j] !== c && text[j] !== '\n') j += text[j] === '\\' ? 2 : 1;
      const stop = j < n && text[j] === c ? j + 1 : j;
      mark(i, stop, 'str'); i = stop; valueBefore = true; continue;
    }
    if (c === '`') { mask[i] = 'str'; frames.push({ start: i + 1, inExpr: false, braces: 0 }); i++; continue; }
    if (c === '/' && !valueBefore) {
      let j = i + 1, inClass = false;
      while (j < n && text[j] !== '\n') {
        const e = text[j];
        if (e === '\\') { j += 2; continue; }
        if (inClass) { if (e === ']') inClass = false; } else if (e === '[') inClass = true; else if (e === '/') break;
        j++;
      }
      if (j < n && text[j] === '/') {
        j++;
        while (j < n && /[A-Za-z]/.test(text[j])) j++;
        mark(i, j, 'str'); i = j; valueBefore = true; continue;
      }
      i++; valueBefore = false; continue;          // a lone `/` on its line: an operator
    }
    if (/[\w$]/.test(c)) {
      let j = i + 1;
      while (j < n && /[\w$]/.test(text[j])) j++;
      valueBefore = !KEYWORDS_BEFORE_EXPRESSION.has(text.slice(i, j));
      i = j; continue;
    }
    if (top && top.inExpr) {                        // punctuation inside a `${…}`
      if (c === '{') top.braces++;
      else if (c === '}') {
        if (top.braces === 0) { mask[i] = 'str'; top.inExpr = false; i++; continue; }
        top.braces--;
      }
    }
    valueBefore = c === ')' || c === ']';
    i++;
  }
  for (const f of frames) templates.push({ start: f.start, end: n, depth: frames.indexOf(f) });  // unterminated
  return { mask, templates };
}

// The text with its comment characters blanked (newlines kept), strings and code kept: columns and line
// numbers are preserved.
function codeOfJs(text) {
  const { mask } = maskJs(text);
  let out = '';
  for (let k = 0; k < text.length; k++) out += mask[k] === 'cut' && text[k] !== '\n' ? ' ' : text[k];
  return out;
}

module.exports = { maskJs, codeOfJs };

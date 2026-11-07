// js-mask.js — label each character of a JavaScript source as code, string or comment, and find its template
// literals: the JS twin of lib/coffee-mask.js, for a reader that must cut comments and keep strings.
//
// maskJs(text, file?) -> { mask, templates }   (`file` only names the source in a refusal)
//   mask[i] is 'code', 'str' (a quoted string, a regex literal, or a template literal's TEXT — its backticks and its
//   `${` / `}` delimiters included, the expressions inside them 'code') or 'cut' (a `//` or `/* … */` comment, or a
//   `#!` first line).
//   templates lists every template literal as { start, end, depth, cooked }, in the order they CLOSE: its TEXT
//   between the backticks (start inclusive, end exclusive), depth 0 for one written in code, 1+ for one nested inside
//   a `${…}`; `cooked` is that text as the program SEES it — each escape (`\n`, `` \` ``, `\\`) read as the
//   character it makes, each `${…}` kept as written. Cooking never adds or removes a line break that is not an
//   escape, so a written `\n` is the one way the two can differ in lines.
//
// It PARSES the text with acorn (vendor/acorn — build-time only, see its README), so what is a regex literal, a
// division, a string or a template is decided by JavaScript's grammar, never by a lexer's guess at the previous
// token. A text that does not parse is REFUSED: maskJs throws `JS_MASK_UNPARSEABLE`, naming the file, the parser's
// message and the position, so a reader of code it cannot read stops loudly instead of guessing. It parses with
// `ecmaVersion: 'latest'` — whatever this Node runs (class fields, `#private`, static blocks), the build reads; the
// tests repo's scripts and macro command files are held to `node --check` by check-tests-syntax.js. Parsed as a
// script first (CommonJS: a top-level `return` is allowed), then as a module.
//
// Readers: lib/tests-repo-code.js, lib/gate-rules.js, lib/what-runs.js, run-selftests.js and the tests repo's
// check-macro-source-discipline.js; lib/call-sites.js parses with the same acorn. Its cases are in
// tests-repo-code-selftest.js.

const acorn = require('../../vendor/acorn/acorn.js');

const OPTIONS = { ecmaVersion: 'latest', allowHashBang: true, allowReturnOutsideFunction: true };

// the AST and comment ranges of `text`, or a thrown JS_MASK_UNPARSEABLE
function parseJs(text, file) {
  let comments, firstError;
  for (const sourceType of ['script', 'module']) {
    comments = [];
    try {
      const ast = acorn.parse(text, Object.assign({ sourceType, onComment: (block, t, start, end) => comments.push([start, end]) }, OPTIONS));
      return { ast, comments };
    } catch (e) { if (!firstError) firstError = e; }
  }
  throw new Error(`JS_MASK_UNPARSEABLE: ${file || 'a text'} is not JavaScript acorn can parse — ${firstError.message}`);
}

function maskJs(text, file) {
  const n = text.length;
  const mask = new Array(n).fill('code');
  const templates = [];
  const mark = (a, b, kind) => { for (let k = a; k < b && k < n; k++) mask[k] = kind; };
  const { ast, comments } = parseJs(text, file);
  // pre-order, so a template's 'str' is laid down before the strings and templates inside its `${…}` re-mark theirs
  const visit = (node, depth) => {
    if (Array.isArray(node)) { for (const x of node) visit(x, depth); return; }
    if (!node || typeof node.type !== 'string') return;
    if (node.type === 'Literal' && (typeof node.value === 'string' || node.regex)) mark(node.start, node.end, 'str');
    if (node.type === 'TemplateLiteral') {
      mark(node.start, node.end, 'str');
      for (let k = 0; k < node.expressions.length; k++) mark(node.quasis[k].end + 2, node.quasis[k + 1].start - 1, 'code');
      const q = node.quasis;
      const cooked = q.map((e, k) => e.value.cooked + (k + 1 < q.length ? text.slice(e.end, q[k + 1].start) : '')).join('');
      templates.push({ start: node.start + 1, end: node.end - 1, depth, cooked });
      for (const e of node.expressions) visit(e, depth + 1);
      return;
    }
    for (const key of Object.keys(node)) {
      if (key === 'type' || key === 'start' || key === 'end') continue;
      const v = node[key];
      if (v && typeof v === 'object') visit(v, depth);
    }
  };
  visit(ast, 0);
  for (const [a, b] of comments) mark(a, b, 'cut');
  if (text.startsWith('#!')) { const e = text.indexOf('\n'); mark(0, e < 0 ? n : e, 'cut'); }
  templates.sort((a, b) => a.end - b.end);
  return { mask, templates };
}

module.exports = { maskJs };

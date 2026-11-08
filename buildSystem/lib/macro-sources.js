'use strict';
// macro-sources.js — WHERE THE MACRO SOURCES ARE: every CoffeeScript text the macro engine compiles (Macro.fromString),
// read as the text it compiles. Two kinds, one reader each; a reader of macro CODE reads both:
//   testMacroSourcesIn(text, file, ast)  a test's command file (JS): the value of its `mainMacroSource`, and each element
//                                        of its `extraSubroutineSources` array (none when that is absent, `null` or
//                                        `undefined`) — what AutomatorEventCommandStartMacro compiles. `ast` is the
//                                        file's parse (lib/js-mask.js parseJs), when the caller has it.
//   verbMacroSourcesIn(text, file)       a CoffeeScript file: the argument of each `Macro.fromString` call that is a
//                                        string literal — MacroToolkit's standard verbs —, read off the bundled
//                                        compiler's lexer (the reading lib/coffee-mask.js takes of every file, so a
//                                        file only the parser refuses, as it does a bare `super`, reads). A file that
//                                        never names `fromString` holds none and is not lexed.
//   verbMacroSources(srcDir)             every src file's verbs: [{ file, sources }], one entry per file holding any.
//                                        (A reader that walks src for its own reasons reads each file it holds through
//                                        verbMacroSourcesIn instead.)
// Each source, in file order: { role: 'main' | 'extra' | 'verb', line, text }, a test's also { start, end }, its span in
// the file inside its backticks (or quotes), the way to the JS around it. `text` is COOKED — the CoffeeScript the page
// compiles, each escape read as the character it makes — and the caller reads it as CoffeeScript, comments and all;
// `line` (1-based) is the file line of its first line, and line k of `text` sits on file line `line + k`.
// Refused, MACRO_SOURCE_UNREADABLE naming the file and the line — never read by a guess:
//   - a source the file does not hold: a test's that is neither a string literal nor a template literal without `${…}`
//     (a `${…}` is computed when the page runs), an `extraSubroutineSources` that is no array (the page compiles each of
//     its elements: a string's elements would be its characters), a verb's that is computed when the page runs (an
//     interpolated string). A verb argument that is a REFERENCE (`Macro.fromString eachSource`, the harness compiling a
//     test's sources) is no source of this file, and is passed over;
//   - a source whose escapes add or remove a line break (a written `\n`, a `\⏎`): a reader reporting `line + k` would
//     name the wrong line. A heredoc's own shape is no such break: the line its opening `"""` ends and the indent its
//     closing `"""` sits on are not its text;
//   - a CoffeeScript file naming `fromString` that does not lex.
// Readers: lib/tests-repo-code.js (a test's sources, for the readers of the tests repo's code), lib/call-sites.js,
// check-layering.js (rule [D]), check-unresolved-sends.js, and the tests repo's check-macro-source-discipline.js,
// aim-census.js, macro-page-lib.js and capture-macro-test-references.js. Cases: lib/macro-sources-selftest.js.

const fs = require('fs');
const path = require('path');
const { parseJs } = require('./js-mask');
const { bundledCoffeeScript } = require('./meta-compiler');

// a line continuation: in a JS template a `\` right before the line break; in a CoffeeScript string, before blanks too
const JS_LINE_CONTINUATION = /(?<!\\)(?:\\\\)*\\\r?\n/;
const COFFEE_LINE_CONTINUATION = /(?<!\\)(?:\\\\)*\\[^\n\S]*\n/;
const unreadable = (file, line, why) => new Error(`MACRO_SOURCE_UNREADABLE: ${file || 'a text'}:${line} — ${why}`);

function testMacroSourcesIn(text, file, ast = parseJs(text, file).ast) {
  const lineAt = (k) => text.slice(0, k).split('\n').length;
  const refuse = (k, why) => { throw unreadable(file, lineAt(k), why); };
  const sources = [];
  const take = (v, role, at) => {
    const isText = !!v && ((v.type === 'Literal' && typeof v.value === 'string') || (v.type === 'TemplateLiteral' && !v.expressions.length));
    if (!isText) refuse(v ? v.start : at, `its ${role} source is neither a string literal nor a template literal without \`\${…}\`, so the file does not hold its text`);
    const start = v.start + 1, end = v.end - 1, raw = text.slice(start, end);
    const cooked = v.type === 'Literal' ? v.value : v.quasis[0].value.cooked;
    if (cooked.split('\n').length !== raw.split('\n').length || JS_LINE_CONTINUATION.test(raw)) {
      refuse(start, `its ${role} source writes a line break as an escape (\\n or \\⏎), so its lines do not sit on the file's`);
    }
    sources.push({ role, line: lineAt(start), start, end, text: cooked });
  };
  const visit = (node) => {
    if (Array.isArray(node)) { for (const x of node) visit(x); return; }
    if (!node || typeof node.type !== 'string') return;
    const key = node.type === 'Property' && !node.computed && (node.key.name || node.key.value);
    if (key === 'mainMacroSource') { take(node.value, 'main'); return; }
    if (key === 'extraSubroutineSources') {
      const v = node.value;
      if ((v.type === 'Literal' && v.value === null) || (v.type === 'Identifier' && v.name === 'undefined')) return;
      if (v.type !== 'ArrayExpression') refuse(v.start, 'its extraSubroutineSources is no array (the page compiles each of its elements)');
      for (const e of v.elements) take(e, 'extra', v.start);
      return;
    }
    for (const k of Object.keys(node)) if (k !== 'type' && node[k] && typeof node[k] === 'object') visit(node[k]);
  };
  visit(ast);
  return sources;
}

let CoffeeScript;                                              // loaded on first use
const OPENS = new Set(['(', '[', '{', 'CALL_START', 'INDEX_START', 'PARAM_START', 'STRING_START', 'REGEX_START', 'INDENT']);
const CLOSES = new Set([')', ']', '}', 'CALL_END', 'INDEX_END', 'PARAM_END', 'STRING_END', 'REGEX_END', 'OUTDENT']);
// a reference: `name`, `@name`, `this.name`, each followed by any `.name`s
const isReference = (arg) => {
  let k = 0;
  if (arg[k] && arg[k][0] === '@') { k++; if (arg[k] && arg[k][0] === 'PROPERTY') k++; }
  else if (arg[k] && (arg[k][0] === 'IDENTIFIER' || arg[k][0] === 'THIS')) k++;
  else return false;
  while (k < arg.length && arg[k][0] === '.' && arg[k + 1] && arg[k + 1][0] === 'PROPERTY') k += 2;
  return k === arg.length;
};
function verbMacroSourcesIn(text, file) {
  if (!text.includes('fromString')) return [];
  CoffeeScript = CoffeeScript || bundledCoffeeScript();
  // what the compiler reads: it drops a leading BOM and every \r before it lexes, and a token's place is on that text
  const read = text.slice(text.charCodeAt(0) === 0xFEFF ? 1 : 0).replace(/\r/g, '');
  let tokens;
  try { tokens = CoffeeScript.tokens(read); } catch (e) {
    throw unreadable(file, e.location ? e.location.first_line + 1 : '?', `it names fromString and does not lex: ${String(e.message).split('\n')[0]}`);
  }
  const lines = read.split('\n');
  const sources = [];
  for (let i = 2; i < tokens.length; i++) {
    const t = tokens[i];
    if (t[0] !== 'PROPERTY' || t[1] !== 'fromString' || tokens[i - 1][0] !== '.' || tokens[i - 2][0] !== 'IDENTIFIER' || tokens[i - 2][1] !== 'Macro') continue;
    if (!tokens[i + 1] || tokens[i + 1][0] !== 'CALL_START') continue;   // named, not called
    const at = t[2].first_line + 1;
    const args = [[]];                                         // the call's arguments, each its tokens
    let depth = 0;
    for (let k = i + 2; k < tokens.length; k++) {
      const u = tokens[k];
      if (depth === 0 && u[0] === 'CALL_END') break;
      if (OPENS.has(u[0])) depth++;
      else if (CLOSES.has(u[0])) depth--;
      if (depth === 0 && u[0] === ',') args.push([]);
      else args[args.length - 1].push(u);
    }
    if (args.length !== 1 || !args[0].length) throw unreadable(file, at, `a Macro.fromString given ${args[0].length ? args.length : 0} arguments, where it compiles one source`);
    const arg = args[0];
    if (isReference(arg)) continue;
    if (arg.length !== 1 || arg[0][0] !== 'STRING') {
      throw unreadable(file, at, 'a Macro.fromString argument computed when the page runs (an interpolated string?), so the file does not hold its text');
    }
    const ld = arg[0][2];
    const raw = ld.first_line === ld.last_line ? lines[ld.first_line].slice(ld.first_column, ld.last_column + 1)
      : [lines[ld.first_line].slice(ld.first_column), ...lines.slice(ld.first_line + 1, ld.last_line), lines[ld.last_line].slice(0, ld.last_column + 1)].join('\n');
    const delimiter = /^("""|''')/.test(raw) ? 3 : 1;
    let body = raw.slice(delimiter, raw.length - delimiter), line = ld.first_line + 1;
    if (delimiter === 3) {                                     // the heredoc's own shape: a blank opening line, its closing indent
      const opening = /^[^\n\S]*\n/.exec(body);
      if (opening) { body = body.slice(opening[0].length); line++; }
      body = body.replace(/\n[^\n\S]*$/, '');
    }
    const cooked = new Function('return ' + arg[0][1])();
    if (cooked.split('\n').length !== body.split('\n').length || COFFEE_LINE_CONTINUATION.test(body)) {
      throw unreadable(file, line, 'its verb source writes a line break as an escape (\\n or \\⏎), so its lines do not sit on the file\'s');
    }
    sources.push({ role: 'verb', line, text: cooked });
  }
  return sources;
}

function verbMacroSources(srcDir) {
  const out = [];
  const walk = (dir) => {
    for (const e of fs.readdirSync(dir, { withFileTypes: true }).sort((a, b) => (a.name < b.name ? -1 : 1))) {
      const p = path.join(dir, e.name);
      if (e.isDirectory()) walk(p);
      else if (e.name.endsWith('.coffee')) {
        const sources = verbMacroSourcesIn(fs.readFileSync(p, 'utf8'), p);
        if (sources.length) out.push({ file: p, sources });
      }
    }
  };
  walk(srcDir);
  return out;
}

module.exports = { testMacroSourcesIn, verbMacroSourcesIn, verbMacroSources };

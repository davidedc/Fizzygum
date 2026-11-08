// tests-repo-code.js — the CODE of the sibling Fizzygum-tests repo, for a gate or census that reads that
// repo's code and must not read its prose.
//
// That repo holds code in three places, and they are what this reads:
//   - the harness sources (Automator-and-test-harness-src/*.coffee);
//   - each test's macro command file (tests/<name>/<name>_automationCommands.js): its CoffeeScript
//     macro sources, which sit in JS template literals (macroSourcesIn, below), and the JS around them;
//   - the Node rigs (scripts/**/*.js), whose page.evaluate bodies call core methods directly.
// Strings are KEPT: a macro or a rig may dispatch a method by its name, and code lives in strings. Comments
// are CUT: a comment calls nothing. And everything else under tests/ is left out — the metadata files
// (descriptive prose: intent, scenario, assertions, provenance, …), the reference-image records (base64
// PNG, ~45 MB) and the generated manifests — none of it is code.
//
// testsRepoCode(root) -> [{ file, kind: 'harness' | 'macro' | 'script', lines }], `lines` being the
// file's lines with comment characters blanked (columns kept — save that a macro source's lines are its COOKED text,
// so on a line holding a JS escape the columns after it move left); [] when the repo is absent. Dot-directories
// (a gitignored `.scratch/` under scripts/) are not read: what a clean checkout lacks must not decide.
//
// JS is PARSED (lib/js-mask.js, on acorn): a comment is cut wherever it starts, a comment marker inside a
// string or a template is text, and a macro file's macro sources are found by the grammar, so a backtick
// inside a comment (every macro file's header names `intent` / `scenario` / … in one) opens nothing. A JS file
// that does not parse is refused loudly (js-mask's JS_MASK_UNPARSEABLE), never read by a guess. The harness and each
// macro source are CoffeeScript, read through lib/coffee-mask.js, the CoffeeScript lexer's own reading; a macro
// source as the text the page compiles, never the escaped text as written (a CoffeeScript `"q\""` is written
// `"q\\""`, and masking that would read the rest of its line as a string).
//
// Readers: census-public-private-calls.js (R4) and check-dead-methods.js (testsRepoCode);
// check-unresolved-sends.js (macroSources: the macro sends); lib/call-sites.js — the reader behind
// check-call-arguments.js and census-call-arity.js — (testsRepoFiles, macroSourcesIn); check-layering.js (rule D, over
// macroSourcesIn); and the tests repo's check-macro-source-discipline.js, aim-census.js, macro-page-lib.js (the
// visualisation's per-step comments) and capture-macro-test-references.js (the screenshot names), all over
// macroSourcesIn — ONE definition of a macro source for every Node reader. Its cases are tests-repo-code-selftest.js.

const fs = require('fs');
const path = require('path');
const { coffeeMask } = require('./coffee-mask');
const { maskJs, parseJs } = require('./js-mask');

const DEFAULT_ROOT = path.resolve(__dirname, '../../../Fizzygum-tests');

function walk(dir, keep, acc) {
  if (!fs.existsSync(dir)) return acc;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    if (e.name === 'node_modules' || e.name === 'automation-assets' || e.name.startsWith('.')) continue;
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, keep, acc);
    else if (keep(e.name)) acc.push(p);
  }
  return acc;
}

const coffeeCode = (text, file) => coffeeMask(text, file).map((line) => line.code);

// The lines of a JS text whose mask is `mask`, its comments blanked (newlines kept).
function uncommented(text, mask) {
  const out = text.split('');
  for (let k = 0; k < out.length; k++) if (mask[k] === 'cut' && out[k] !== '\n') out[k] = ' ';
  return out.join('').split('\n');
}
const jsCode = (text, file) => uncommented(text, maskJs(text, file).mask);

// A macro command file: JS whose macro sources are CoffeeScript. JS comments are cut by the parse; each macro source's
// lines are its cooked text with its comments cut by coffee-mask, laid on the file lines it occupies (its first and last
// lines keep the JS before and after its backticks). Any other string in the file is a JS string, kept whole.
function macroCode(text, file) {
  const parsed = parseJs(text, file);
  const lines = uncommented(text, maskJs(text, file, parsed).mask);
  const column = (k) => k - (text.lastIndexOf('\n', k - 1) + 1);
  // the last source first, so a splice never moves the columns of a source still to come on the same line
  for (const s of macroSourcesIn(text, file, parsed.ast).reverse()) {
    const code = coffeeCode(s.text, `${file} (its macro source from line ${s.line})`);
    const first = s.line - 1, last = first + code.length - 1;
    const head = lines[first].slice(0, column(s.start)), tail = lines[last].slice(column(s.end));
    code.forEach((c, k) => { lines[first + k] = (k === 0 ? head : '') + c + (k === code.length - 1 ? tail : ''); });
  }
  return lines;
}

// THE MACRO SOURCES of a test's command file — what the harness compiles (AutomatorEventCommandStartMacro): the value
// of its `mainMacroSource`, and each element of its `extraSubroutineSources` array (none when that is absent, `null` or
// `undefined`), found in the parse, in file order, as [{ role: 'main' | 'extra', line, start, end, text }]. `text` is
// COOKED — the CoffeeScript the page compiles, each JS escape read as the character it makes — and the caller reads it
// as CoffeeScript, comments and all; `start`/`end` is its span in the file, inside its backticks (or quotes), the way to
// the JS around it; `line` (1-based) is the file line of its first line, and line k of `text` sits on file line
// `line + k`. Refused, MACRO_SOURCE_UNREADABLE naming the file and the line — never read by a guess:
//   - a source that is neither a string literal nor a template literal without `${…}` (the file does not hold its
//     text: a `${…}` is computed when the page runs), and an `extraSubroutineSources` that is no array (the page
//     compiles each of its elements: a string's elements would be its characters);
//   - a source whose escapes add or remove a line break (a written `\n`, a `\⏎`): a reader reporting `line + k` would
//     name the wrong line.
// `ast` is the file's parse (lib/js-mask.js parseJs), when the caller has it.
const LINE_CONTINUATION = /(?<!\\)(?:\\\\)*\\\r?\n/;
function macroSourcesIn(text, file, ast = parseJs(text, file).ast) {
  const lineAt = (k) => text.slice(0, k).split('\n').length;
  const refuse = (k, why) => { throw new Error(`MACRO_SOURCE_UNREADABLE: ${file || 'a text'}:${lineAt(k)} — ${why}`); };
  const sources = [];
  const take = (v, role, at) => {
    const isText = !!v && ((v.type === 'Literal' && typeof v.value === 'string') || (v.type === 'TemplateLiteral' && !v.expressions.length));
    if (!isText) refuse(v ? v.start : at, `its ${role} source is neither a string literal nor a template literal without \`\${…}\`, so the file does not hold its text`);
    const start = v.start + 1, end = v.end - 1, raw = text.slice(start, end);
    const cooked = v.type === 'Literal' ? v.value : v.quasis[0].value.cooked;
    if (cooked.split('\n').length !== raw.split('\n').length || LINE_CONTINUATION.test(raw)) {
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

// The macro sources of each test's command file: [{ file, sources }], sources as macroSourcesIn gives them. For a gate
// that reads macro CODE as CoffeeScript and must not see the JS around it.
function macroSources(root = DEFAULT_ROOT) {
  return macroFiles(root).map((file) => ({ file, sources: macroSourcesIn(fs.readFileSync(file, 'utf8'), file) }));
}

// THE FILE SET — which files of the tests repo are code, by kind: { harness, macro, script }, each sorted absolute
// paths; undefined when the repo is absent (no harness or no tests/ directory). The readers of the repo's code as a
// whole take their files from here (testsRepoCode, macroSources, the call-sites table), so those cannot disagree about
// what is code; the gates that walk the tests themselves (the macro source discipline gate, aim-census, layering's
// [D]) read each command file they find through macroSourcesIn.
function macroFiles(root) {
  const tests = path.join(root, 'tests');
  return fs.existsSync(tests) ? walk(tests, (n) => n.endsWith('_automationCommands.js'), []).sort() : [];
}
function testsRepoFiles(root = DEFAULT_ROOT) {
  const harness = path.join(root, 'Automator-and-test-harness-src');
  if (!fs.existsSync(harness) || !fs.existsSync(path.join(root, 'tests'))) return undefined;
  return {
    harness: walk(harness, (n) => n.endsWith('.coffee'), []).sort(),
    macro: macroFiles(root),
    script: walk(path.join(root, 'scripts'), (n) => n.endsWith('.js'), []).sort(),
  };
}

function testsRepoCode(root = DEFAULT_ROOT) {
  const files = testsRepoFiles(root);
  if (!files) return [];
  const read = { harness: coffeeCode, macro: macroCode, script: jsCode };
  const out = [];
  for (const kind of ['harness', 'macro', 'script'])
    for (const file of files[kind]) out.push({ file, kind, lines: read[kind](fs.readFileSync(file, 'utf8'), file) });
  return out;
}

module.exports = { testsRepoCode, testsRepoFiles, macroSources, macroSourcesIn, coffeeCode, jsCode, macroCode, DEFAULT_ROOT };

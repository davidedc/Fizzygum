// tests-repo-code.js — the CODE of the sibling Fizzygum-tests repo, for a gate or census that reads that
// repo's code and must not read its prose.
//
// That repo holds code in three places, and they are what this reads:
//   - the harness sources (Automator-and-test-harness-src/*.coffee);
//   - each test's macro command file (tests/<name>/<name>_automationCommands.js): its CoffeeScript
//     macro sources, which sit in JS template literals, and the JS around them;
//   - the Node rigs (scripts/**/*.js), whose page.evaluate bodies call core methods directly.
// Strings are KEPT: a macro or a rig may dispatch a method by its name, and code lives in strings. Comments
// are CUT: a comment calls nothing. And everything else under tests/ is left out — the metadata files
// (descriptive prose: intent, scenario, assertions, provenance, …), the reference-image records (base64
// PNG, ~45 MB) and the generated manifests — none of it is code.
//
// testsRepoCode(root) -> [{ file, kind: 'harness' | 'macro' | 'script', lines }], `lines` being the
// file's lines with comment characters blanked (columns kept); [] when the repo is absent. Dot-directories
// (a gitignored `.scratch/` under scripts/) are not read: what a clean checkout lacks must not decide.
//
// JS is LEXED (lib/js-mask.js): a comment is cut wherever it starts, a comment marker inside a string or a
// template is text, and a macro file's template literals are found by the lexer, so a backtick inside a
// comment (every macro file's header names `intent` / `scenario` / … in one) opens nothing. Each top-level
// template literal of a macro file is CoffeeScript and is read through lib/coffee-mask.js.
//
// Stated limits: the two masks' own (lib/js-mask.js's header), and lib/coffee-mask.js's misreadings of
// CoffeeScript. Some can CUT code: js-mask's regex read as a division when it holds `/*`; coffee-mask's `#`
// inside a regex literal or heregex, a "…" string spanning lines, a quote nested in `#{…}`. In a reference
// gate (dead methods, R4) a cut can only invent a finding, which fails the build loudly with its site in
// view; in census-call-arity it hides a call site. Measured 2026-11-06 against the CoffeeScript lexer,
// js-tokens and acorn over the whole repo: none cuts a word of code.
//
// Readers: census-public-private-calls.js (R4), check-dead-methods.js, census-call-arity.js
// (testsRepoSources) and check-unresolved-sends.js (macroSources: the macro sends). Its cases are
// tests-repo-code-selftest.js.

const fs = require('fs');
const path = require('path');
const { codeOfCoffeeLine } = require('./coffee-mask');
const { maskJs } = require('./js-mask');

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

function coffeeCode(text) {
  let state = null;
  return text.split('\n').map((line) => { const r = codeOfCoffeeLine(line, state); state = r.state; return r.code; });
}

// JS with its comments blanked (newlines kept).
function jsCode(text) {
  const { mask } = maskJs(text);
  const out = text.split('');
  for (let k = 0; k < out.length; k++) if (mask[k] === 'cut' && out[k] !== '\n') out[k] = ' ';
  return out.join('').split('\n');
}

// A macro command file: JS whose top-level template literals are CoffeeScript macro sources. JS comments
// are cut by the lexer, CoffeeScript comments by coffee-mask over each template's text.
function macroCode(text) {
  const { mask, templates } = maskJs(text);
  const out = text.split('');
  for (let k = 0; k < out.length; k++) if (mask[k] === 'cut' && out[k] !== '\n') out[k] = ' ';
  for (const t of templates) {
    if (t.depth !== 0) continue;
    const coffee = coffeeCode(text.slice(t.start, t.end)).join('\n');
    for (let k = 0; k < coffee.length; k++) out[t.start + k] = coffee[k];
  }
  return out.join('').split('\n');
}

// The CoffeeScript macro sources of each test, alone: every top-level template literal of every macro command
// file, as { file, sources: [{ line, text }] } (`line` 1-based, where the source's first line sits in the
// file; `text` raw — the caller reads it as CoffeeScript, comments and all). For a gate that reads macro
// CODE as CoffeeScript and must not see the JS around it.
function macroSources(root = DEFAULT_ROOT) {
  const tests = path.join(root, 'tests');
  if (!fs.existsSync(tests)) return [];
  return walk(tests, (n) => n.endsWith('_automationCommands.js'), []).sort().map((file) => {
    const text = fs.readFileSync(file, 'utf8');
    const sources = maskJs(text).templates.filter((t) => t.depth === 0)
      .map((t) => ({ line: text.slice(0, t.start).split('\n').length, text: text.slice(t.start, t.end) }));
    return { file, sources };
  });
}

function testsRepoCode(root = DEFAULT_ROOT) {
  const harness = path.join(root, 'Automator-and-test-harness-src');
  const tests = path.join(root, 'tests');
  const scripts = path.join(root, 'scripts');
  if (!fs.existsSync(harness) || !fs.existsSync(tests)) return [];
  const out = [];
  for (const file of walk(harness, (n) => n.endsWith('.coffee'), []).sort())
    out.push({ file, kind: 'harness', lines: coffeeCode(fs.readFileSync(file, 'utf8')) });
  for (const file of walk(tests, (n) => n.endsWith('_automationCommands.js'), []).sort())
    out.push({ file, kind: 'macro', lines: macroCode(fs.readFileSync(file, 'utf8')) });
  for (const file of walk(scripts, (n) => n.endsWith('.js'), []).sort())
    out.push({ file, kind: 'script', lines: jsCode(fs.readFileSync(file, 'utf8')) });
  return out;
}

module.exports = { testsRepoCode, macroSources, coffeeCode, jsCode, macroCode, DEFAULT_ROOT };

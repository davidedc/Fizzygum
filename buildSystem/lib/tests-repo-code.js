// tests-repo-code.js — the CODE of the sibling Fizzygum-tests repo, for a census that asks "does
// anything outside src/ name this method?".
//
// That repo calls Fizzygum's methods from three places, and they are what this reads:
//   - the harness sources (Automator-and-test-harness-src/*.coffee);
//   - each test's macro command file (tests/<name>/<name>_automationCommands.js): its CoffeeScript
//     macro sources, which sit in JS template literals (`…`), and the JS around them;
//   - the Node rigs (scripts/**/*.js), whose page.evaluate bodies call core methods directly.
// Strings are KEPT: a macro or a rig may dispatch a method by its name. Comments are CUT: a comment
// that names a method calls nothing. And everything else under tests/ is left out — the metadata
// files (descriptive prose: intent, scenario, assertions, provenance, …), the reference-image records
// (base64 PNG, ~45 MB) and the generated manifests — none of it is code.
//
// testsRepoCode(root) -> [{ file, kind: 'harness' | 'macro' | 'script', lines }], `lines` being the
// file's lines with comment characters blanked (columns kept); [] when the repo is absent. Dot-directories
// (a gitignored `.scratch/` under scripts/) are not read: what a clean checkout lacks must not decide.
//
// Stated limits. These keep a word that is really a comment, which can only hide a candidate:
//   - a JS comment is cut only when it STARTS a line (`//`, or a `/* … */` block whose later lines look
//     like comment lines, a leading `*` or the closing `*/`), so a trailing `// …` counts;
//   - a macro file whose backticks do not pair is read as JS whole, its CoffeeScript comments included.
// These can CUT code, which would invent a candidate and fail the build loudly (rule [U] names it, and
// its caller is right there to see). They are lib/coffee-mask.js's misreadings of CoffeeScript: a `#`
// inside a regex literal or heregex, a "…" string spanning lines, or a quote nested in `#{…}` ends the
// string early. Also a JS line inside a template literal that starts with `//` or `/*`. Measured
// 2026-11-06, a token-by-token comparison against the CoffeeScript lexer and js-tokens over the whole
// repo: none cuts a word of code.

const fs = require('fs');
const path = require('path');
const { codeOfCoffeeLine } = require('./coffee-mask');

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

// JS with the comments that START a line blanked: `// …`, and `/* … */` blocks (text after a block's
// closing `*/` is kept). A trailing `// …` after code is kept. A block runs on only while its lines look
// like comment lines (blank, a leading `*`, or the one holding `*/`): a line starting with `/*` inside a
// template literal then cuts that one line, not everything up to some later `*/`.
function jsCode(text) {
  let inBlock = false;
  return text.split('\n').map((line) => {
    const lead = line.length - line.trimStart().length;
    if (inBlock) {
      const end = line.indexOf('*/');
      if (end >= 0) { inBlock = false; return ' '.repeat(end + 2) + line.slice(end + 2); }
      if (lead === line.length || line.startsWith('*', lead)) return ' '.repeat(line.length);
      inBlock = false;
      return line;
    }
    if (line.startsWith('//', lead)) return ' '.repeat(line.length);
    if (line.startsWith('/*', lead)) {
      const end = line.indexOf('*/', lead + 2);
      if (end < 0) { inBlock = true; return ' '.repeat(line.length); }
      return ' '.repeat(end + 2) + line.slice(end + 2);
    }
    return line;
  });
}

// A macro command file: JS, with the CoffeeScript macro sources in template literals. Even-numbered
// backtick-separated parts are JS, odd ones CoffeeScript; unpaired backticks = read it all as JS.
function macroCode(text) {
  const parts = text.split('`');
  if (parts.length % 2 === 0) return jsCode(text);
  const out = parts.map((part, i) => (i % 2 === 0 ? jsCode(part) : coffeeCode(part)).join('\n'));
  return out.join('`').split('\n');
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

module.exports = { testsRepoCode, coffeeCode, jsCode, macroCode, DEFAULT_ROOT };

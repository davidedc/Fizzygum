// tests-repo-code.js — the CODE of the sibling Fizzygum-tests repo, for a gate or census that reads that
// repo's code and must not read its prose.
//
// That repo holds code in three places, and they are what this reads:
//   - the harness sources (Automator-and-test-harness-src/*.coffee);
//   - each test's macro command file (tests/<name>/<name>_automationCommands.js): its CoffeeScript
//     macro sources, which sit in JS template literals (lib/macro-sources.js), and the JS around them;
//   - the Node rigs (scripts/**/*.js), whose page.evaluate bodies call core methods directly.
// Strings are KEPT: a macro or a rig may dispatch a method by its name, and code lives in strings. Comments
// are CUT: a comment calls nothing. And everything else under tests/ is left out — the metadata files
// (descriptive prose: intent, scenario, assertions, provenance, …), the reference-image records (base64
// PNG, ~45 MB) and the generated manifests — none of it is code.
//
// testsRepoCode(root) -> [{ file, kind: 'harness' | 'macro' | 'script', lines }], `lines` being the
// file's lines with comment characters blanked (columns kept — save that a macro source's lines are its COOKED text,
// so on a line holding a JS escape the columns after it move left); a root holding no tests repo is refused (it
// throws), never read as no code. The scripts are the tooling's own files (lib/what-runs.js scriptFiles): never a dot
// entry (a gitignored `.scratch/`), a node_modules or a __pycache__ — what a clean checkout lacks must not decide — and
// a symlink is refused (TOOLING_TREE_MALFORMED).
//
// JS is PARSED (lib/js-mask.js, on acorn): a comment is cut wherever it starts, a comment marker inside a
// string or a template is text, and a macro file's macro sources are found by the grammar, so a backtick
// inside a comment (every macro file's header names `intent` / `scenario` / … in one) opens nothing. A JS file
// that does not parse is refused loudly (js-mask's JS_MASK_UNPARSEABLE), never read by a guess. The harness and each
// macro source are CoffeeScript, read through lib/coffee-mask.js, the CoffeeScript lexer's own reading; a macro
// source as the text the page compiles, never the escaped text as written (a CoffeeScript `"q\""` is written
// `"q\\""`, and masking that would read the rest of its line as a string).
//
// Readers: census-public-private-calls.js (R4) and check-dead-methods.js (testsRepoCode); check-unresolved-sends.js
// (macroSources: the macro sends); lib/call-sites.js — the reader behind check-call-arguments.js and
// census-call-arity.js — (testsRepoFiles); and every reader that walks the tests one by one (THE TESTS, below): the
// gates check-layering.js [D], check-hand-lists.js, and the tests repo's check-macro-source-discipline.js, aim-census.js,
// check-tests-syntax.js, check-visualisations.js and check-refs.js; its manifest generator (scripts/lib/tests-manifests.js);
// its runners and capture tools. Its cases are tests-repo-code-selftest.js.

const fs = require('fs');
const path = require('path');
const { coffeeMask } = require('./coffee-mask');
const { maskJs, parseJs } = require('./js-mask');
const { testMacroSourcesIn } = require('./macro-sources');
const { harnessFiles, TESTS_REPO: DEFAULT_ROOT, byCodePoint } = require('./source-files');
const { scriptFiles, DEFAULT_LAYOUT } = require('./what-runs');

// the Node rigs: the .js files of the tooling's own files (what-runs.js scriptFiles, the one definition) under scripts/
function rigFiles(root) {
  const scripts = path.join(root, 'scripts') + path.sep;
  return scriptFiles({ ...DEFAULT_LAYOUT, tests: root }).filter((f) => f.startsWith(scripts) && f.endsWith('.js')).sort(byCodePoint);
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
  for (const s of testMacroSourcesIn(text, file, parsed.ast).reverse()) {
    const code = coffeeCode(s.text, `${file} (its macro source from line ${s.line})`);
    const first = s.line - 1, last = first + code.length - 1;
    const head = lines[first].slice(0, column(s.start)), tail = lines[last].slice(column(s.end));
    code.forEach((c, k) => { lines[first + k] = (k === 0 ? head : '') + c + (k === code.length - 1 ? tail : ''); });
  }
  return lines;
}

// THE TESTS — what the harness plays, and the two files it loads for each, by name. Every DIRECTORY of tests/ is a test
// (the manifest lists exactly these: scripts/lib/tests-manifests.js), each one named `SystemTest_<x>` and holding its
// metadata, `<name>.js`, and its commands, `<name>_automationCommands.js` — the paths AutomatorLoader's _loadTestMetadata
// and loadTest build from the name. A directory that is not such a test is refused, TESTS_DIRECTORY_MALFORMED naming
// it, never skipped: the harness would play it, so a reader that passed it over would pass a test it never read.
// `testsDir` is the tests/ directory (a gate's --tests-dir= rail hands it another).
//   testNames(testsDir)          every test's name, sorted by code point; [] when there is no tests/ directory
//   testNameOf(word)             the test a word names: `macroX` and `SystemTest_macroX` both name SystemTest_macroX
//   TEST_PREFIX                  `SystemTest_`, which every test's name starts with
//   commandFileOf(testsDir, n)   test n's command file
//   metadataFileOf(testsDir, n)  test n's metadata file
//   commandFiles(testsDir)       every test's command file
const DEFAULT_TESTS = path.join(DEFAULT_ROOT, 'tests');
const TEST_PREFIX = 'SystemTest_';
const commandFileOf = (testsDir, name) => path.join(testsDir, name, name + '_automationCommands.js');
const metadataFileOf = (testsDir, name) => path.join(testsDir, name, name + '.js');
const testNameOf = (word) => (word.startsWith(TEST_PREFIX) ? word : TEST_PREFIX + word);
function testNames(testsDir = DEFAULT_TESTS) {
  if (!fs.existsSync(testsDir)) return [];
  const names = fs.readdirSync(testsDir, { withFileTypes: true }).filter((e) => e.isDirectory()).map((e) => e.name).sort(byCodePoint);
  for (const name of names) {
    const refuse = (why) => { throw new Error(`TESTS_DIRECTORY_MALFORMED: ${path.join(testsDir, name)} — ${why}`); };
    if (!name.startsWith(TEST_PREFIX)) refuse(`a directory of tests/ is a test the harness plays, and a test is named ${TEST_PREFIX}<name>`);
    // spelled exactly: macOS answers existsSync for any letter case, and a page served from a case-sensitive file
    // system loads only the exact name
    const held = new Set(fs.readdirSync(path.join(testsDir, name)));
    for (const [file, what] of [[metadataFileOf(testsDir, name), 'metadata'], [commandFileOf(testsDir, name), 'command']]) {
      if (!held.has(path.basename(file))) refuse(`it has no ${what} file ${path.basename(file)}, which the harness loads by its name`);
    }
  }
  return names;
}
const commandFiles = (testsDir = DEFAULT_TESTS) => testNames(testsDir).map((name) => commandFileOf(testsDir, name));

// The macro sources of each test's command file: [{ file, sources }], sources as lib/macro-sources.js testMacroSourcesIn
// gives them. For a gate that reads macro CODE as CoffeeScript and must not see the JS around it.
function macroSources(root = DEFAULT_ROOT) {
  return commandFiles(path.join(root, 'tests')).map((file) => ({ file, sources: testMacroSourcesIn(fs.readFileSync(file, 'utf8'), file) }));
}

// THE FILE SET — which files of the tests repo are code, by kind: { harness, macro, script }, each sorted absolute
// paths; undefined for a root holding no tests repo, as harnessFiles answers it (a fact about the path handed in: every
// build requires the repo) — each reader refuses that answer loudly (lib/planted-src.js, testsRepoCode below,
// lib/call-sites.js). The harness is lib/source-files.js's harnessFiles, the one definition every
// gate reading the compiled sources shares (it refuses a tests repo without a harness, SOURCE_TREE_MALFORMED); the macros
// are THE TESTS' command files. The readers of the repo's code as a whole take their files from here (testsRepoCode,
// the call-sites table), so those cannot disagree about what is code; a gate that reads the tests one by one takes them
// from testNames.
function testsRepoFiles(root = DEFAULT_ROOT) {
  const harness = harnessFiles(root);
  if (!harness) return undefined;
  return {
    harness,
    macro: commandFiles(path.join(root, 'tests')),
    script: rigFiles(root),
  };
}

function testsRepoCode(root = DEFAULT_ROOT) {
  const files = testsRepoFiles(root);
  if (!files) throw new Error(`tests-repo-code: no tests repo at ${root}`);
  const read = { harness: coffeeCode, macro: macroCode, script: jsCode };
  const out = [];
  for (const kind of ['harness', 'macro', 'script'])
    for (const file of files[kind]) out.push({ file, kind, lines: read[kind](fs.readFileSync(file, 'utf8'), file) });
  return out;
}

module.exports = { testsRepoCode, testsRepoFiles, macroSources, coffeeCode, jsCode, macroCode, DEFAULT_ROOT,
  DEFAULT_TESTS, TEST_PREFIX, testNames, testNameOf, commandFileOf, metadataFileOf, commandFiles };

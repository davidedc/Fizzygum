'use strict';
// tests-repo-code-selftest.js — the tests-repo reader's cases (lib/tests-repo-code.js), on a throwaway fixture repo:
// each a file and the words a scan of what the reader keeps must, or must not, find; a command file's macro sources
// through the file set (macroSources) — by their KEYS, in file order (an extra written before the main source, a
// template that is no source), each one's cooked text, file line and span (the in-memory cases of the reader itself are
// lib/macro-sources-selftest.js); macroCode laying two sources on one line; an unparseable file refused; and THE TESTS — every directory of tests/ is one, holding
// its two files by its name, so a command file anywhere else is no test's, and a directory that is not such a test is
// refused. Run by buildSystem/run-selftests.js on every build.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { testsRepoCode, macroSources, macroCode, testNames, testNameOf, commandFileOf, metadataFileOf } = require('./tests-repo-code');
const t = require('./selftest-verdict').cases('tests-repo-code');

const fixture = fs.mkdtempSync(path.join(os.tmpdir(), 'tests-repo-code-'));
const put = (rel, text) => { const p = path.join(fixture, rel); fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, text); };
put('Automator-and-test-harness-src/H.coffee', 'x = "#{a}"; harnessCall()\n# harnessComment()\n');
put('tests/SystemTest_t/SystemTest_t.js', 'var SystemTest_t = { "intent": "metadataProse is named here" };\n');
// a stray template that is no macro source, the extra source written BEFORE the main one, and a CoffeeScript string
// `"q\""` — written `"q\\""`, which masked as written would read the comment after it as a string
const MACRO_FILE = 'tests/SystemTest_t/SystemTest_t_automationCommands.js';
put(MACRO_FILE,
  '// HEADER: the `headerTick` / `headerTock` fields\n// jsComment\nvar stray = `strayTemplateWord()`;\n' +
  'var c = { "extraSubroutineSources": [`helper = ->\n  w.extraCall() # extraComment\n`],\n"mainMacroSource":\n' +
  '`m = ->\n  # macroComment\n  w.macroCall() # macroTrailing\n  w["macroString"]()\n  z = "q\\\\"" # cookedOnlyComment\n' +
  '  q = 7 // 2`\n}; // jsTrailing\n');
put('tests/SystemTest_t/automation-assets/x/ref.js', 'var r = "referenceRecord";\n');
// a command file that is not its directory's own: the harness never loads it, so it is no test's code
put('tests/SystemTest_t/nested/SystemTest_n_automationCommands.js', 'var c = { "mainMacroSource": `nestedMacroCall()` };\n');
put('tests/testsManifest.js', 'var m = ["manifestEntry"];\n');
put('scripts/r.js', '#!/usr/bin/env shebangWord\n  // scriptComment\n/* scriptBlock\n   scriptBlockToo */ scriptAfterBlock()\n' +
  'page.evaluate(() => w.scriptCall()); // scriptTrailing\nconst k = n / 8; // afterDivision\n' +
  // a regex literal holding `//` must not start a comment, and one holding a backtick must not open a template
  'const slashes = /\\/\\//; afterSlashRegex()\nconst tick = /`/; afterTickRegex() // tickComment\nmore()\n');
put('scripts/node_modules/dep.js', 'nodeModule()\n');
put('scripts/.scratch/probe.js', 'scratchProbe()\n');
put('scripts/t.js', 'const css = `\n/* rule\n// alsoTemplateText\n`; page.evaluate(() => w.afterTemplate());\nw.later();\n');
const seen = new Set();
for (const { lines } of testsRepoCode(fixture)) for (const l of lines) for (const w of l.match(/[A-Za-z_]\w*/g) || []) seen.add(w);
// macroSources: the sources BY THEIR KEYS — never by order (the extra comes first here), never a stray template — in
// file order, each one's CoffeeScript alone from its own file line, its span the text between its backticks
const ms = macroSources(fixture);
const srcs = ms.length === 1 ? ms[0].sources : [];
const shape = srcs.map((s) => `${s.role}@${s.line}`).join(' ');
t.check(shape === 'extra@4 main@8', `macroSources gives the extra and main sources by their keys, in file order, each from its line (${shape || 'none'})`);
const [extra, main] = srcs;
t.check(srcs.length === 2 && /extraCall/.test(extra.text) && /macroCall/.test(main.text)
  && srcs.every((s) => !/strayTemplateWord|mainMacroSource|HEADER|jsTrailing/.test(s.text)), 'each macro source is its CoffeeScript alone, none of the JS around it');
const fileText = fs.readFileSync(path.join(fixture, MACRO_FILE), 'utf8');
t.check(srcs.length === 2 && srcs.every((s) => fileText[s.start - 1] === '`' && fileText[s.end] === '`')
  && fileText.slice(main.start, main.end).includes('"q\\\\""') && main.text.includes('"q\\""'),
  'a macro source\'s span is the text between its backticks, as written; its text, as cooked');
fs.rmSync(fixture, { recursive: true, force: true });
const MUST = ['harnessCall', 'macroCall', 'macroString', 'extraCall', 'strayTemplateWord', 'scriptCall', 'scriptAfterBlock',
  'afterTemplate', 'later', 'afterSlashRegex', 'afterTickRegex', 'more', 'rule', 'alsoTemplateText'];
const MUST_NOT = ['harnessComment', 'metadataProse', 'headerTick', 'headerTock', 'jsComment', 'macroComment',
  'macroTrailing', 'extraComment', 'cookedOnlyComment', 'jsTrailing', 'referenceRecord', 'manifestEntry', 'shebangWord',
  'scriptComment', 'scriptBlock', 'scriptBlockToo', 'scriptTrailing', 'afterDivision', 'tickComment', 'nodeModule',
  'scratchProbe', 'nestedMacroCall'];
for (const w of MUST) t.check(seen.has(w), `tests-repo code names ${w}`);
for (const w of MUST_NOT) t.check(!seen.has(w), `tests-repo code does not name ${w}`);
// JS that does not parse (an unterminated template) is REFUSED, naming why — never read by a guess
let refusal = '';
try { macroCode('// lead\nvar c = `m = ->\n  # openComment\n  stillCode()\n'); } catch (e) { refusal = e.message; }
t.check(/^JS_MASK_UNPARSEABLE: .*Unterminated template/.test(refusal), `an unparseable macro file is refused, naming why (${refusal || 'no throw'})`);
// macroCode lays each source's masked text on its file line, keeping the JS before and after its backticks — two
// sources on ONE line, the first shortened by cooking (`\``), the second's columns untouched by the first's splice
const twoOnALine = macroCode('var c = { "extraSubroutineSources": [`a() # c\\`a`], "mainMacroSource": `bCall() # cb` };\n', 'f.js')[0];
t.check(twoOnALine === 'var c = { "extraSubroutineSources": [`a()      `], "mainMacroSource": `bCall()     ` };',
  `two macro sources on one line are each masked in place, the JS around them kept (${JSON.stringify(twoOnALine)})`);
// a macro source is the COOKED text — what the page compiles — not the escapes as written: the file holds
// `x = "a\\nb" # see \`it\``, the page compiles `x = "a\nb" # see `it``
const cookFixture = fs.mkdtempSync(path.join(os.tmpdir(), 'tests-repo-code-cook-'));
fs.mkdirSync(path.join(cookFixture, 'tests', 'SystemTest_c'), { recursive: true });
fs.writeFileSync(path.join(cookFixture, 'tests', 'SystemTest_c', 'SystemTest_c.js'), 'var SystemTest_c = {};\n');
fs.writeFileSync(path.join(cookFixture, 'tests', 'SystemTest_c', 'SystemTest_c_automationCommands.js'),
  'var c = { "mainMacroSource": `m = ->\n  x = "a\\\\nb" # see \\`it\\`\n` };\n');
const cooked = macroSources(cookFixture);
const cookedText = cooked.length === 1 ? cooked[0].sources[0].text : '';
t.check(cookedText.includes('x = "a\\nb" # see `it`') && !cookedText.includes('\\`'),
  `a macro source reads its escapes as the page does (${JSON.stringify(cookedText)})`);
fs.rmSync(cookFixture, { recursive: true, force: true });

// THE TESTS: every directory of tests/, each holding its metadata and its command file by its name; a directory that is
// not such a test is refused through every reader (here macroSources), naming it — never skipped
const layout = fs.mkdtempSync(path.join(os.tmpdir(), 'tests-repo-code-layout-'));
const layoutTests = path.join(layout, 'tests');
const makeTest = (name, files = ['meta', 'commands']) => {
  fs.mkdirSync(path.join(layoutTests, name), { recursive: true });
  if (files.includes('meta')) fs.writeFileSync(path.join(layoutTests, name, name + '.js'), `var ${name} = {};\n`);
  if (files.includes('commands')) fs.writeFileSync(path.join(layoutTests, name, name + '_automationCommands.js'), 'var c = { "mainMacroSource": `m()` };\n');
};
makeTest('SystemTest_b'); makeTest('SystemTest_a'); makeTest('SystemTest_a_b');
fs.writeFileSync(path.join(layoutTests, 'testsManifest.js'), 'var m = [];\n');   // a file of tests/ is no test
for (const [what, plant, unplant, expect] of [
  ['a directory not named SystemTest_*', () => makeTest('scratch'), () => fs.rmSync(path.join(layoutTests, 'scratch'), { recursive: true }),
    /^TESTS_DIRECTORY_MALFORMED: \S+\/tests\/scratch — a directory of tests\/ is a test the harness plays, and a test is named SystemTest_<name>$/],
  ['a test with no metadata file', () => makeTest('SystemTest_noMeta', ['commands']), () => fs.rmSync(path.join(layoutTests, 'SystemTest_noMeta'), { recursive: true }),
    /^TESTS_DIRECTORY_MALFORMED: \S+\/tests\/SystemTest_noMeta — it has no metadata file SystemTest_noMeta\.js, which the harness loads by its name$/],
  ['a test whose metadata file differs in letter case', () => { makeTest('SystemTest_case', ['commands']); fs.writeFileSync(path.join(layoutTests, 'SystemTest_case', 'SystemTest_Case.js'), ''); },
    () => fs.rmSync(path.join(layoutTests, 'SystemTest_case'), { recursive: true }),
    /^TESTS_DIRECTORY_MALFORMED: \S+\/tests\/SystemTest_case — it has no metadata file SystemTest_case\.js, which the harness loads by its name$/],
  ['a test with no command file (a copy whose files keep the old name)', () => { makeTest('SystemTest_copy', ['meta']); fs.writeFileSync(path.join(layoutTests, 'SystemTest_copy', 'SystemTest_old_automationCommands.js'), ''); },
    () => fs.rmSync(path.join(layoutTests, 'SystemTest_copy'), { recursive: true }),
    /^TESTS_DIRECTORY_MALFORMED: \S+\/tests\/SystemTest_copy — it has no command file SystemTest_copy_automationCommands\.js, which the harness loads by its name$/],
]) {
  plant();
  let refusal = '';
  try { macroSources(layout); } catch (e) { refusal = e.message; }
  t.check(expect.test(refusal), `${what} is refused, naming it (${refusal || 'read without refusal'})`);
  unplant();
}
const names = testNames(layoutTests).join(' ');
t.check(names === 'SystemTest_a SystemTest_a_b SystemTest_b', `the tests are tests/' directories, sorted (${names})`);
t.check(macroSources(layout).map((m) => path.basename(m.file)).join(' ') === 'SystemTest_a_automationCommands.js SystemTest_a_b_automationCommands.js SystemTest_b_automationCommands.js',
  'every test\'s command file, by its name');
t.check(testNameOf('macroX') === 'SystemTest_macroX' && testNameOf('SystemTest_macroX') === 'SystemTest_macroX', 'a word names its test with or without the prefix');
t.check(testNames(path.join(layout, 'absent')).length === 0, 'no tests/ directory holds no tests');
t.check(commandFileOf(layoutTests, 'SystemTest_a') === path.join(layoutTests, 'SystemTest_a', 'SystemTest_a_automationCommands.js')
  && metadataFileOf(layoutTests, 'SystemTest_a') === path.join(layoutTests, 'SystemTest_a', 'SystemTest_a.js'), 'a test\'s two files, by its name');
fs.rmSync(layout, { recursive: true, force: true });

t.done();

'use strict';
// tests-repo-code-selftest.js — the tests-repo reader's cases (lib/tests-repo-code.js), on a throwaway fixture repo:
// each a file and the words a scan of what the reader keeps must, or must not, find; macroSources giving a macro's
// CoffeeScript alone; an unterminated template read to the end. Run by buildSystem/run-selftests.js on every build.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { testsRepoCode, macroSources, macroCode } = require('./tests-repo-code');
const t = require('./selftest-verdict').cases('tests-repo-code');

const fixture = fs.mkdtempSync(path.join(os.tmpdir(), 'tests-repo-code-'));
const put = (rel, text) => { const p = path.join(fixture, rel); fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, text); };
put('Automator-and-test-harness-src/H.coffee', 'x = "#{a}"; harnessCall()\n# harnessComment()\n');
put('tests/SystemTest_t/SystemTest_t.js', 'var SystemTest_t = { "intent": "metadataProse is named here" };\n');
put('tests/SystemTest_t/SystemTest_t_automationCommands.js',
  '// HEADER: the `headerTick` / `headerTock` fields\n// jsComment\nvar c = { "mainMacroSource":\n' +
  '`m = ->\n  # macroComment\n  w.macroCall() # macroTrailing\n  w["macroString"]()\n  q = 7 // 2`\n}; // jsTrailing\n');
put('tests/SystemTest_t/automation-assets/x/ref.js', 'var r = "referenceRecord";\n');
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
// macroSources: the template's CoffeeScript alone, starting on its own line, and none of the JS around it
const ms = macroSources(fixture);
const one = ms.length === 1 && ms[0].sources.length === 1 ? ms[0].sources[0] : undefined;
const msOk = !!one && one.line === 4 && /macroCall/.test(one.text) && !/mainMacroSource|HEADER|jsTrailing/.test(one.text);
t.check(msOk, `macroSources gives the macro's CoffeeScript alone, from its line (${one ? one.line : 'none'})`);
fs.rmSync(fixture, { recursive: true, force: true });
const MUST = ['harnessCall', 'macroCall', 'macroString', 'scriptCall', 'scriptAfterBlock', 'afterTemplate', 'later',
  'afterSlashRegex', 'afterTickRegex', 'more', 'rule', 'alsoTemplateText'];
const MUST_NOT = ['harnessComment', 'metadataProse', 'headerTick', 'headerTock', 'jsComment', 'macroComment',
  'macroTrailing', 'jsTrailing', 'referenceRecord', 'manifestEntry', 'shebangWord', 'scriptComment', 'scriptBlock',
  'scriptBlockToo', 'scriptTrailing', 'afterDivision', 'tickComment', 'nodeModule', 'scratchProbe'];
for (const w of MUST) t.check(seen.has(w), `tests-repo code names ${w}`);
for (const w of MUST_NOT) t.check(!seen.has(w), `tests-repo code does not name ${w}`);
// JS that does not parse (an unterminated template) is REFUSED, naming why — never read by a guess
let refusal = '';
try { macroCode('// lead\nvar c = `m = ->\n  # openComment\n  stillCode()\n'); } catch (e) { refusal = e.message; }
t.check(/^JS_MASK_UNPARSEABLE: .*Unterminated template/.test(refusal), `an unparseable macro file is refused, naming why (${refusal || 'no throw'})`);
// a macro source is the COOKED text — what the page compiles — not the escapes as written: the file holds
// `x = "a\\nb" # see \`it\``, the page compiles `x = "a\nb" # see `it``
const cookFixture = fs.mkdtempSync(path.join(os.tmpdir(), 'tests-repo-code-cook-'));
fs.mkdirSync(path.join(cookFixture, 'tests', 'SystemTest_c'), { recursive: true });
fs.writeFileSync(path.join(cookFixture, 'tests', 'SystemTest_c', 'SystemTest_c_automationCommands.js'),
  'var c = { "mainMacroSource": `m = ->\n  x = "a\\\\nb" # see \\`it\\`\n` };\n');
const cooked = macroSources(cookFixture);
const cookedText = cooked.length === 1 ? cooked[0].sources[0].text : '';
t.check(cookedText.includes('x = "a\\nb" # see `it`') && !cookedText.includes('\\`'),
  `a macro source reads its escapes as the page does (${JSON.stringify(cookedText)})`);
fs.rmSync(cookFixture, { recursive: true, force: true });

t.done();

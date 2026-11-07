'use strict';
// gate-rules-selftest.js — lib/gate-rules.js, seen on every exit path a gate can take: each case is a tiny gate written
// to a temp dir and RUN, since what the registry decides happens on the way out of a real process. Run by
// buildSystem/run-selftests.js on every build.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const { parseRulesLine, readRules } = require('./gate-rules');
const t = require('./selftest-verdict').cases('gate-rules');

const LIB = path.join(__dirname, 'gate-rules.js');
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'gate-rules-selftest-'));
process.on('exit', () => fs.rmSync(dir, { recursive: true, force: true }));

let n = 0;
function gate(body, header = '') {
  const file = path.join(dir, `fake-gate-${++n}.js`);
  fs.writeFileSync(file, `${header}'use strict';\nconst rules = require(${JSON.stringify(LIB)}).forGate(__filename);\n${body}\n`);
  const r = spawnSync(process.execPath, [file], { encoding: 'utf8' });
  return { status: r.status, out: `${r.stdout}${r.stderr}`, rules: parseRulesLine(`${r.stdout}${r.stderr}`), name: path.basename(file, '.js') };
}

{
  const r = gate(`console.error(rules.fired('RULE_ONE', '  the violation line'));\nif (false) rules.fired('RULE_TWO', 'x');\nprocess.exit(1);`);
  t.check(r.status === 1, 'an exit 1 that fired a rule stays exit 1', r.out);
  t.check(/^  the violation line$/m.test(r.out), 'fired() returns its text unchanged', r.out);
  t.check(r.rules && r.rules.gate === r.name && [...r.rules.fired].join() === 'RULE_ONE' && [...r.rules.of].sort().join() === 'RULE_ONE,RULE_TWO',
    'the RULES line names what fired and every literal id the source can fire', r.out);
}
{
  const r = gate(`process.exitCode = 1;`);
  t.check(r.status === 2 && /RULELESS_FAILURE/.test(r.out) && !r.rules, 'an exit 1 naming no rule is RULELESS_FAILURE, exit 2', r.out);
}
{
  const r = gate(`throw new Error('a crash');`);
  t.check(r.status === 2 && /RULELESS_FAILURE/.test(r.out), 'an uncaught exception is operational (exit 2), never a verdict', r.out);
}
{
  const r = gate(`rules.fired('RULE_ONE', 'x');\nprocess.exit(0);`);
  t.check(r.status === 2 && /RULE_FIRED_BUT_PASSED RULE_ONE/.test(r.out), 'a rule fired on an exit 0 is RULE_FIRED_BUT_PASSED, exit 2', r.out);
}
{
  const r = gate(`rules.fired('RULE_ONE', 'x');\nprocess.exit(2);`);
  t.check(r.status === 2 && r.rules && [...r.rules.fired].join() === 'RULE_ONE',
    'an INVALID (exit 2) that fired a rule keeps its exit and prints the RULES line, so a proof can see it', r.out);
  const quiet = gate(`process.exit(2);`);
  t.check(quiet.status === 2 && !quiet.rules, 'an INVALID that fired nothing prints no RULES line', quiet.out);
}
{
  const r = gate(`const id = 'RULE_' + 'COMPUTED';\nrules.fired(id, 'x');\nprocess.exit(1);`);
  t.check(r.status === 2 && /neither a literal \.fired\( id nor declared/.test(r.out), 'a computed id nobody declared stops the run (exit 2)', r.out);
}
{
  const r = gate(`const TABLE = [{ id: 'table-one' }, { id: 'table-two' }];\nrules.declare(TABLE.map((e) => e.id));\nrules.fired(TABLE[1].id, 'x');\nprocess.exit(1);`);
  t.check(r.status === 1 && r.rules && [...r.rules.fired].join() === 'table-two' && [...r.rules.of].sort().join() === 'table-one,table-two',
    'a declared table id may fire, and every declared id is in `of`', r.out);
}
{
  const r = gate(`rules.fired('RULE_ONE', 'x');\nprocess.exit(1);\nrules.fired('RULE_DEEP', 'y');`, `// bite-unplantable: RULE_DEEP — reached only by a 24-deep chain\n`);
  t.check(r.status === 1 && r.rules && !r.rules.of.has('RULE_DEEP') && r.rules.unplantable.has('RULE_DEEP'),
    'an id stated unplantable in the header is left out of `of` and listed apart', r.out);
}
{
  const r = gate(`process.exit(0);`, `// bite-unplantable: RULE_GONE — this gate no longer has the rule\n`);
  t.check(r.status === 2 && /BITE_UNPLANTABLE_STALE RULE_GONE/.test(r.out), 'an unplantable line naming a rule the gate cannot fire is stale, exit 2, even on a pass', r.out);
}
{
  const r = gate(`process.exit(0);`);
  t.check(r.status === 0 && !r.out.trim(), 'a clean pass prints nothing of its own', r.out);
}
{
  // a gate REQUIRED as a library (a self-test using its engine) must not take over its host's exit
  const lib = path.join(dir, 'library-gate.js');
  fs.writeFileSync(lib, `const rules = require(${JSON.stringify(LIB)}).forGate(__filename);\nmodule.exports = { rules };\n`);
  const host = path.join(dir, 'host.js');
  fs.writeFileSync(host, `require(${JSON.stringify(lib)});\nprocess.exitCode = 1;\n`);
  const r = spawnSync(process.execPath, [host], { encoding: 'utf8' });
  t.check(r.status === 1 && !/RULELESS_FAILURE/.test(r.stdout + r.stderr), "a gate required as a library leaves its host's exit code alone", r.stdout + r.stderr);
}
{
  const { literal } = readRules(`// rules.fired('IN_COMMENT', 'x')\nconst s = "rules.fired('IN_STRING', 'x')";\nrules.fired("IN_CODE", 'x');\n`);
  t.check([...literal].join() === 'IN_CODE', 'only a .fired( in CODE names a rule: comments and strings do not', [...literal].join());
}
t.check(parseRulesLine('[g] RULES fired: A B · of: A B C · unplantable: D').unplantable.has('D') && !parseRulesLine('no line'),
  'the RULES line reads back, and its absence reads as undefined');
{
  // a gate that runs another prints the inner gate's line first: asked for its own, it gets its own
  const out = '[inner] RULES fired: X · of: X Y\n[outer] RULES fired: A · of: A B';
  const own = parseRulesLine(out, 'outer');
  t.check(own && own.gate === 'outer' && [...own.fired].join() === 'A' && !parseRulesLine(out, 'absent') &&
    parseRulesLine(out).gate === 'inner', "the RULES line of a NAMED gate is that gate's, not the first in the output", JSON.stringify(own));
}

// A gate's report reaches a SLOW reader whole: the gate prints far more than a pipe holds, then exits at once, while
// its reader takes nothing for half a second (a proof's spawn under a loaded pool). Async pipe writes lose all of it.
(async () => {
  const file = path.join(dir, 'chatty-gate.js');
  fs.writeFileSync(file, `'use strict';\nconst rules = require(${JSON.stringify(LIB)}).forGate(__filename);\n` +
    `const line = 'x'.repeat(499);\nfor (let i = 0; i < 2000; i++) console.log(i + ' ' + line);\n` +
    `console.error(rules.fired('RULE_ONE', '  the violation line, printed last'));\nprocess.exit(1);\n`);
  const r = await new Promise((resolve) => {
    const c = require('child_process').spawn(process.execPath, [file]);
    let out = '', err = '';
    c.stdout.pause(); c.stderr.pause();
    setTimeout(() => {
      c.stdout.on('data', (d) => { out += d; }); c.stderr.on('data', (d) => { err += d; });
      c.stdout.resume(); c.stderr.resume();
    }, 500);
    c.on('close', (status) => resolve({ status, out, err }));
  });
  const lines = r.out.split('\n').filter((l) => /^\d+ x/.test(l)).length;
  t.check(r.status === 1 && lines === 2000 && /the violation line, printed last/.test(r.err) && parseRulesLine(r.out + r.err),
    'a gate that prints 1 MB and exits at once reaches a slow reader whole: every line, its violation line, its RULES line',
    `exit ${r.status}, ${lines} of 2000 lines`);
  t.done();
})();

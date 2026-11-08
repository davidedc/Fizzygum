'use strict';
// planted-src-selftest.js — lib/planted-src.js's proveGate, held to what it promises: a correct proof passes, and a
// proof that misses a rule, expects the wrong one, plants a neighbour, has a failing control, carries an edit that
// did not apply, or leaks one run's plant into the next FAILS. Each proof is a child process over a fake gate in a
// temp dir, since proveGate prints a verdict of its own. And a planted tree's reset leaves no directory a plant made.
// Run by buildSystem/run-selftests.js on every build.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const t = require('./selftest-verdict').cases('planted-src');

const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'planted-src-selftest-'));
process.on('exit', () => fs.rmSync(dir, { recursive: true, force: true }));
const fixture = path.join(dir, 'fixture');
fs.mkdirSync(fixture);
fs.writeFileSync(path.join(fixture, 'Base.coffee'), 'class Base\n  marker: -> "base"\n');

// The fake gate: a file named PlantOne/PlantTwo fires its rule; a file holding "neighbour" fires RULE_ONE too.
const gate = path.join(dir, 'fake-gate.js');
fs.writeFileSync(gate, `'use strict';
const fs = require('fs'), path = require('path');
const rules = require(${JSON.stringify(path.join(__dirname, 'gate-rules.js'))}).forGate(__filename);
const { dirArg, rejectUnknownArgs } = require(${JSON.stringify(path.join(__dirname, 'cli-args.js'))});
const argv = process.argv.slice(2);
rejectUnknownArgs(argv, ['--src='], 'fake-gate');
const SRC = dirArg(argv, '--src=', '/nowhere', 'fake-gate');
let bad = 0;
for (const f of fs.readdirSync(SRC).sort()) {
  const text = fs.readFileSync(path.join(SRC, f), 'utf8');
  if (f === 'PlantOne.coffee' || /neighbour/.test(text)) { console.error(rules.fired('RULE_ONE', '  ' + f + ': rule one')); bad++; }
  if (f === 'PlantTwo.coffee') { console.error(rules.fired('RULE_TWO', '  ' + f + ': rule two')); bad++; }
}
if (!/"base"/.test(fs.readFileSync(path.join(SRC, 'Base.coffee'), 'utf8'))) { console.error(rules.fired('RULE_ONE', '  Base.coffee: edited')); bad++; }
if (bad) process.exit(1);
console.log('[fake-gate] OK');
`);

function proof(body) {
  const file = path.join(dir, `proof-${Math.random().toString(36).slice(2)}.js`);
  fs.writeFileSync(file, `'use strict';
const { proveGate } = require(${JSON.stringify(path.join(__dirname, 'planted-src.js'))});
const ONE = { label: 'rule one', plants: { 'PlantOne.coffee': 'class PlantOne\\n' }, expect: { RULE_ONE: /^  PlantOne\\.coffee: rule one$/m } };
const TWO = { label: 'rule two', plants: { 'PlantTwo.coffee': 'class PlantTwo\\n' }, expect: { RULE_TWO: /^  PlantTwo\\.coffee: rule two$/m } };
const base = { name: 'fake-proof', gate: ${JSON.stringify(gate)}, from: ${JSON.stringify(fixture)}, pass: /\\[fake-gate\\] OK/ };
${body}
`);
  const r = spawnSync(process.execPath, [file], { encoding: 'utf8' });
  return { status: r.status, out: `${r.stdout}${r.stderr}` };
}
const failsOn = (r, label) => r.status === 1 && new RegExp('^  FAIL ' + label, 'm').test(r.out);

let r = proof(`proveGate({ ...base, control: { plants: { 'Sanctioned.coffee': 'class Sanctioned\\n' } }, runs: [ONE, TWO] });`);
t.check(r.status === 0 && /SELFTEST PASS/.test(r.out), 'a proof planting every rule, with a passing control, passes', r.out);

r = proof(`proveGate({ ...base, runs: [ONE] });`);
t.check(failsOn(r, 'every rule the gate can fire is planted') && /never planted: RULE_TWO/.test(r.out), 'a rule no run plants fails the proof, named', r.out);

r = proof(`proveGate({ ...base, runs: [{ ...ONE, expect: { RULE_TWO: /PlantOne/ } }, TWO] });`);
t.check(failsOn(r, 'bites RULE_TWO'), 'expecting a rule the run did not fire fails, even when the line regex matches', r.out);

r = proof(`proveGate({ ...base, runs: [{ ...ONE, plants: { ...ONE.plants, 'PlantTwo.coffee': 'class PlantTwo\\n' } }, TWO] });`);
t.check(failsOn(r, 'rule one: fires only the rules it plants') && /also fired: RULE_TWO/.test(r.out), 'a plant that trips a rule it does not expect fails', r.out);

r = proof(`proveGate({ ...base, control: { plants: { 'Neighbour.coffee': '# a neighbour\\n' } }, runs: [ONE, TWO] });`);
t.check(failsOn(r, 'the control'), 'a control that fails fails the proof', r.out);

r = proof(`proveGate({ ...base, runs: [{ ...ONE, edits: [['Base.coffee', /no such text/, 'x']] }, TWO] });`);
t.check(failsOn(r, 'rule one: every plant applies'), 'an in-copy edit that matched nothing fails (drift is loud)', r.out);

r = proof(`proveGate({ ...base, runs: [{ label: 'edit', edits: [['Base.coffee', /"base"/, '"edited"']], expect: { RULE_ONE: /^  Base\\.coffee: edited$/m } }, TWO] });`);
t.check(r.status === 0, 'an in-copy edit applies, and reset() restores the file before the next run', r.out);

r = proof(`const fs = require('fs');
proveGate({ ...base, runs: [ONE, TWO], after: (t, res) => t.check(!fs.existsSync(res.tree.dir + '/PlantOne.coffee'), 'reset removed the plant') });`);
t.check(r.status === 0 && /ok   reset removed the plant/.test(r.out), "one run's plant never leaks into the next (reset)", r.out);

// reset() leaves the tree as `from` has it: a directory a plant made goes with the plant (a reader of directories — a
// tests tree, where every directory is a test — would otherwise meet an empty one in the next run), and one `from`
// holds stays, empty or not
const { plantedTree } = require('./planted-src');
fs.mkdirSync(path.join(fixture, 'kept'));
const tree = plantedTree({ from: fixture });
tree.plant('made/deeper/Plant.coffee', 'class Plant\n');
tree.plant('kept/Plant.coffee', 'class Plant\n');
tree.reset();
t.check(!fs.existsSync(path.join(tree.dir, 'made')) && fs.existsSync(path.join(tree.dir, 'kept')) && fs.existsSync(path.join(tree.dir, 'Base.coffee')),
  'reset() removes the directories a plant made, and keeps the ones the copy holds');
const empty = plantedTree({ from: null });
empty.plant('SystemTest_x/SystemTest_x.js', '');
empty.reset();
t.check(fs.readdirSync(empty.dir).length === 0, 'reset() of a fixture tree (from: null) leaves it empty');
fs.rmdirSync(path.join(fixture, 'kept'));

t.done();

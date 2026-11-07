'use strict';
// cli-args-selftest.js — lib/cli-args.js's refusals, each seen in a real process (a refusal exits 2). Run by
// buildSystem/run-selftests.js on every build.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const t = require('./selftest-verdict').cases('cli-args');

const LIB = JSON.stringify(path.join(__dirname, 'cli-args.js'));
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'cli-args-selftest-'));
process.on('exit', () => fs.rmSync(dir, { recursive: true, force: true }));
const aFile = path.join(dir, 'a-file.txt');
fs.writeFileSync(aFile, 'x');

const script = path.join(dir, 'rail.js');
fs.writeFileSync(script, `const { dirArg, rejectPositionalArgs, rejectUnknownArgs } = require(${LIB});
const argv = process.argv.slice(2);
rejectUnknownArgs(argv, ['--src='], 'rail');
rejectPositionalArgs(argv, 'rail', 'a tree is named with --src=DIR');
console.log('SRC=' + dirArg(argv, '--src=', '/the/default', 'rail'));
`);
const run = (...args) => {
  const r = spawnSync(process.execPath, [script, ...args], { cwd: dir, encoding: 'utf8' });
  return { status: r.status, out: `${r.stdout}${r.stderr}` };
};

let r = run();
t.check(r.status === 0 && /^SRC=\/the\/default$/m.test(r.out), 'no rail: the default tree', r.out);
r = run('--src=' + dir);
t.check(r.status === 0 && r.out.includes('SRC=' + dir), 'a rail naming a directory: that directory, absolute', r.out);
r = run('--src=.');
t.check(r.status === 0 && (r.out.includes('SRC=' + fs.realpathSync(dir)) || r.out.includes('SRC=' + dir)), 'a relative rail resolves against the cwd', r.out);
r = run('--src=');
t.check(r.status === 2 && /is empty/.test(r.out), 'an EMPTY rail is refused (it would name the cwd)', r.out);
r = run('--src=' + path.join(dir, 'no-such-dir'));
t.check(r.status === 2 && /names no such directory/.test(r.out), 'a rail naming nothing is refused', r.out);
r = run('--src=' + aFile);
t.check(r.status === 2 && /names a file, not a directory/.test(r.out), 'a rail naming a file is refused', r.out);
r = run('--src=' + dir, '--src=' + dir);
t.check(r.status === 2 && /more than once/.test(r.out), 'a rail given twice is refused', r.out);
r = run(dir);
t.check(r.status === 2 && /unexpected argument/.test(r.out), 'a positional argument is refused', r.out);
r = run('--sorc=' + dir);
t.check(r.status === 2 && /unknown argument '--sorc=/.test(r.out), 'an unknown flag is refused', r.out);

const fileScript = path.join(dir, 'file-rail.js');
fs.writeFileSync(fileScript, `const { fileArg } = require(${LIB});\nconsole.log('PARTS=' + fileArg(process.argv.slice(2), '--parts=', '/the/default.json', 'rail'));\n`);
const runFile = (...args) => {
  const r = spawnSync(process.execPath, [fileScript, ...args], { cwd: dir, encoding: 'utf8' });
  return { status: r.status, out: `${r.stdout}${r.stderr}` };
};
r = runFile('--parts=' + aFile);
t.check(r.status === 0 && r.out.includes('PARTS=' + aFile), 'a file rail naming a file: that file', r.out);
r = runFile('--parts=');
t.check(r.status === 2 && /is empty/.test(r.out), 'an EMPTY file rail is refused', r.out);
r = runFile('--parts=' + dir);
t.check(r.status === 2 && /names a directory, not a file/.test(r.out), 'a file rail naming a directory is refused', r.out);
r = runFile('--parts=' + path.join(dir, 'nope.json'));
t.check(r.status === 2 && /names no such file/.test(r.out), 'a file rail naming nothing is refused', r.out);
r = runFile('--parts', aFile);
t.check(r.status === 2 && /--parts takes its value after "="/.test(r.out), 'a file rail written with a space is refused (its value would be dropped)', r.out);

const dirScript = path.join(dir, 'dir-rail.js');
fs.writeFileSync(dirScript, `const { dirArg } = require(${LIB});\nconsole.log('SRC=' + dirArg(process.argv.slice(2), '--src=', '/the/default', 'rail'));\n`);
const d = spawnSync(process.execPath, [dirScript, '--src', dir], { cwd: dir, encoding: 'utf8' });
t.check(d.status === 2 && /--src takes its value after "="/.test(`${d.stdout}${d.stderr}`),
  'a directory rail written with a space is refused (its value would be dropped)', `${d.stdout}${d.stderr}`);

t.done();

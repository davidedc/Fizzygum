'use strict';
// fg-supervisor-selftest.js — lib/fg-supervisor.js (how fg starts a program and makes sure it, and everything it
// started, ends) on tiny node programs, with alarms and graces in milliseconds, so the whole file runs in a few
// seconds on every build. Each case is a row of docs/archive/fg-node-port-plan.md §4: an exit code passes through (A1); a
// program killed by a signal is 128+n and its log says which (A2); a program past its alarm is killed WITH its
// children, 142, and its log says so (A3), even one that ignores SIGTERM (A4); a descendant a program leaves behind
// dies with it (A5); output goes to a file descriptor (A6); a program that cannot start is 127 or 126 with its reason
// (A7); a grandchild holding the output open does not hold the run (A8); a program ending as its alarm fires has one
// outcome (A9); fg and its ancestors are never signalled; an interrupted fg kills its trees and says so (B1); a closed
// stdout does not end fg (B4); the exit watchdog exits with fg's code (B5); the sleep note reads the two clocks (B7).

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn, spawnSync } = require('child_process');
const t = require('./selftest-verdict').cases('fg-supervisor');
const S = require('./fg-supervisor');

const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'fg-supervisor-selftest-'));
const prog = (name, code) => { const p = path.join(dir, name); fs.writeFileSync(p, code); return p; };
const node = (file, ...args) => [process.execPath, file, ...args];
const logFile = (name) => path.join(dir, name + '.log');
const withLog = async (name, fn) => {
  const fd = fs.openSync(logFile(name), 'w');
  try { return await fn(fd); } finally { fs.closeSync(fd); }
};
const read = (name) => { try { return fs.readFileSync(logFile(name), 'utf8'); } catch (e) { return ''; } };
const pidAlive = (pid) => { try { process.kill(pid, 0); return true; } catch (e) { return e.code === 'EPERM'; } };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// a program that starts a grandchild (its pid written to a file), then behaves as `then` says. One that leaves its
// grandchild behind lives 800 ms first: a descendant is seen by the supervisor's snapshots while the program runs, and
// under a loaded build (every self-test at once) a snapshot can be that late
const PARENT = prog('parent.js', `
const { spawn } = require('child_process');
const [pidFile, then, ms] = process.argv.slice(2);
const g = spawn(process.execPath, ['-e', 'setInterval(() => {}, 1000)'], { stdio: then === 'hold-output' ? 'inherit' : 'ignore', detached: then === 'leave' });
require('fs').writeFileSync(pidFile, String(g.pid));
if (then === 'leave' || then === 'hold-output') { g.unref(); setTimeout(() => process.exit(0), Number(ms)); }
else if (then === 'ignore-term') { process.on('SIGTERM', () => {}); setInterval(() => {}, 1000); }
else setInterval(() => {}, 1000);
`);
const grandchild = (name) => Number(fs.readFileSync(path.join(dir, name + '.pid'), 'utf8'));

(async () => {
  // the A cases are independent programs: they run at once, then each is judged
  const timed = async (fn) => { const t0 = Date.now(); const r = await fn(); return { ...r, ms: Date.now() - t0 }; };
  const [a1, a2, a3, a4, a5, a7, a7b, a8, a9] = await Promise.all([
    withLog('a1', (fd) => S.run({ argv: node(prog('exit5.js', 'console.log("hello"); process.exit(5);')), stdout: fd, stderr: fd })),
    withLog('a2', (fd) => S.run({ argv: node(prog('selfkill.js', 'process.kill(process.pid, "SIGKILL");')), stdout: fd, stderr: fd, label: 'selfkill' })),
    timed(() => withLog('a3', (fd) => S.run({ argv: node(PARENT, path.join(dir, 'a3.pid'), 'hang'), stdout: fd, stderr: fd, alarmMs: 400, alarmSecs: 0.4, graceMs: 300, trackMs: 50, label: 'hang' }))),
    timed(() => withLog('a4', (fd) => S.run({ argv: node(PARENT, path.join(dir, 'a4.pid'), 'ignore-term'), stdout: fd, stderr: fd, alarmMs: 300, alarmSecs: 0.3, graceMs: 300, trackMs: 50 }))),
    withLog('a5', (fd) => S.run({ argv: node(PARENT, path.join(dir, 'a5.pid'), 'leave', '800'), stdout: fd, stderr: fd, graceMs: 300, trackMs: 50, label: 'leaver' })),
    withLog('a7', (fd) => S.run({ argv: [path.join(dir, 'no-such-program')], stdout: fd, stderr: fd })),
    withLog('a7b', (fd) => S.run({ argv: [prog('not-executable.sh', 'echo hi\n')], stdout: fd, stderr: fd })),
    timed(() => withLog('a8', (fd) => S.run({ argv: node(PARENT, path.join(dir, 'a8.pid'), 'hold-output', '800'), stdout: fd, stderr: fd, graceMs: 300, trackMs: 50 }))),
    (async () => {
      let settled = 0;
      const p9 = S.run({ argv: node(prog('quick.js', 'setTimeout(() => process.exit(0), 150);')), stdout: 'ignore', stderr: 'ignore', alarmMs: 150, alarmSecs: 0.15, graceMs: 100 });
      p9.then(() => settled++);
      const r = await p9;
      await sleep(300);
      return { ...r, settled };
    })(),
  ]);
  await sleep(50);
  // A1: an exit code passes through; A6: output goes to the file descriptor
  t.check(a1.rc === 5 && read('a1') === 'hello\n', 'an exit code passes through, the output in the log (A1, A6)', JSON.stringify(a1) + read('a1'));
  // A2: killed by a signal
  t.check(a2.rc === 137 && /selfkill was killed by SIGKILL/.test(read('a2')), 'a program killed by a signal is 128+n, its log naming the signal (A2)', JSON.stringify(a2) + read('a2'));
  // A3: past its alarm, the program and its child are killed: 142, one line in its log
  t.check(a3.rc === 142 && a3.timedOut && /timed out after 0\.4 s — hang: its process tree was killed/.test(read('a3')),
    'a program past its alarm is 142, its log saying so (A3)', JSON.stringify(a3) + read('a3'));
  t.check(!pidAlive(grandchild('a3')), 'its child is killed with it: the TREE, not the one process (A3)');
  t.check(a3.ms < 6000, 'and the run ends, bounded by the alarm and the grace (a loaded build stretches both)', String(a3.ms));
  // A4: one that ignores SIGTERM is killed after the grace, the same 142
  t.check(a4.rc === 142 && !pidAlive(grandchild('a4')) && a4.ms < 6000, 'a program that ignores SIGTERM is killed after the grace, 142 (A4)', JSON.stringify(a4));
  // A5: a descendant left behind (detached into a group of its own, as puppeteer's browsers are) dies with the program
  t.check(a5.rc === 0 && !pidAlive(grandchild('a5')) && /leaver left 1 process\(es\) behind: killed/.test(read('a5')),
    'a descendant still alive when the program ends is killed, the log saying so (A5)', JSON.stringify(a5) + read('a5'));
  // A7: a program that cannot start: 127 not found, 126 otherwise, the reason in the log; never a hang
  t.check(a7.rc === 127 && /could not start .*no-such-program/.test(read('a7')), 'a program not found is 127, the reason in its log (A7)', JSON.stringify(a7) + read('a7'));
  t.check(a7b.rc === 126 && /could not start/.test(read('a7b')), 'a program that cannot be executed is 126 (A7)', JSON.stringify(a7b) + read('a7b'));
  // A8: a grandchild holding the output open does not hold the run: its end is the program's EXIT
  t.check(a8.rc === 0 && a8.ms < 6000, 'a grandchild holding the output file open does not hold the run: the run ends at the program\'s exit (A8)', JSON.stringify(a8));
  t.check(!pidAlive(grandchild('a8')), 'and it is killed as one left behind (A5)');
  // A9: a program ending just as its alarm fires: one outcome, the promise settled once
  t.check(a9.settled === 1 && (a9.rc === 0 || a9.rc === 142), 'a program ending as its alarm fires has ONE outcome (A9)', JSON.stringify(a9));

  // the tree reading, on a synthetic table; fg and its ancestors are never signalled
  const table = new Map([[1, { pid: 1, ppid: 0, start: 'a' }], [10, { pid: 10, ppid: 1, start: 'b' }], [11, { pid: 11, ppid: 10, start: 'c' }],
    [12, { pid: 12, ppid: 11, start: 'd' }], [20, { pid: 20, ppid: 1, start: 'e' }]]);
  t.check(S.descendantsOf(10, table).map((e) => e.pid).join() === '11,12', 'descendantsOf walks parent links, nearest first');
  const keep = S.protectedPids(S.snapshot());
  t.check(keep.has(process.pid) && keep.has(process.ppid), 'fg itself and its parent are protected from every signal');
  // a reused pid (the same pid, another start time) and fg itself are never signalled
  const sleeper = require('child_process').spawn(process.execPath, ['-e', 'setInterval(() => {}, 1000)'], { stdio: 'ignore' });
  await sleep(150);
  const now = S.snapshot();
  const hit = S.signalEntries([{ pid: sleeper.pid, start: 'not its start time' }, { pid: process.pid, start: now.get(process.pid).start }], 'SIGTERM', now);
  await sleep(100);
  t.check(hit.length === 0 && pidAlive(sleeper.pid), 'a pid whose start time is not the recorded one (a reused pid), and fg itself, are never signalled', JSON.stringify(hit));
  sleeper.kill('SIGKILL');
  // a timeout kills its program even when no snapshot can be taken (no `ps` on PATH): through the program's own handle
  const noPs = prog('no-ps.js', `
const S = require(${JSON.stringify(path.join(__dirname, 'fg-supervisor.js'))});
S.run({ argv: [process.execPath, '-e', 'setInterval(() => {}, 1000)'], stdout: 'ignore', stderr: 'ignore', alarmMs: 300, alarmSecs: 0.3, graceMs: 200 })
  .then((r) => { console.log('rc=' + r.rc + ' snapshot=' + S.snapshot().size); process.exit(0); });
`);
  const np = spawnSync(process.execPath, [noPs], { encoding: 'utf8', timeout: 8000, env: { PATH: '/nonexistent' } });
  t.check(/^rc=142 snapshot=0$/m.test(np.stdout), 'a timeout kills its program when `ps` cannot run (no snapshot): 142, not a hang', np.stdout + np.stderr);

  // B1: an interrupted fg kills every live tree and hands the signal to its caller
  const guarded = prog('guarded.js', `
const S = require(${JSON.stringify(path.join(__dirname, 'fg-supervisor.js'))});
S.guard({ onInterrupt: async (sig) => { require('fs').writeFileSync(${JSON.stringify(path.join(dir, 'b1.done'))}, sig); }, onInternalError: async () => 2 });
S.run({ argv: [process.execPath, ${JSON.stringify(PARENT)}, ${JSON.stringify(path.join(dir, 'b1.pid'))}, 'hang'], stdout: 'ignore', stderr: 'ignore', trackMs: 50 });
console.log('started');
`);
  const b1 = spawn(process.execPath, [guarded], { stdio: ['ignore', 'pipe', 'ignore'] });
  await new Promise((res) => b1.stdout.once('data', res));
  await sleep(150);
  const b1Child = grandchild('b1');
  b1.kill('SIGTERM');
  const b1rc = await new Promise((res) => b1.on('exit', (c) => res(c)));
  await sleep(50);
  t.check(b1rc === 143 && fs.readFileSync(path.join(dir, 'b1.done'), 'utf8') === 'SIGTERM' && !pidAlive(b1Child),
    'a SIGTERM to fg kills every live tree, hands the signal to its caller and exits 143 (B1)', `rc ${b1rc}, child alive ${pidAlive(b1Child)}`);

  // B3: an error thrown in fg kills every live tree and is the caller's (INVALID, 2)
  const thrower = prog('thrower.js', `
const S = require(${JSON.stringify(path.join(__dirname, 'fg-supervisor.js'))});
S.guard({ onInterrupt: async () => 1, onInternalError: async (e) => { require('fs').writeFileSync(${JSON.stringify(path.join(dir, 'b3.done'))}, e.message); return 2; } });
S.run({ argv: [process.execPath, ${JSON.stringify(PARENT)}, ${JSON.stringify(path.join(dir, 'b3.pid'))}, 'hang'], stdout: 'ignore', stderr: 'ignore', trackMs: 50 });
setTimeout(() => { throw new Error('a planted bug'); }, 300);
`);
  const b3 = spawnSync(process.execPath, [thrower], { encoding: 'utf8', timeout: 8000 });
  await sleep(50);
  t.check(b3.status === 2 && fs.readFileSync(path.join(dir, 'b3.done'), 'utf8') === 'a planted bug' && !pidAlive(grandchild('b3')),
    'an error thrown in fg kills every live tree and exits 2 (B3)', `status ${b3.status} ${b3.stderr.slice(0, 200)}`);

  // B4: a closed stdout does not end fg: it finishes its run
  const writer = prog('writer.js', `
const S = require(${JSON.stringify(path.join(__dirname, 'fg-supervisor.js'))});
let i = 0;
const tick = setInterval(() => { S.out('line ' + (i++) + '\\n'.repeat(1) + 'x'.repeat(4096) + '\\n'); if (i === 60) { clearInterval(tick); require('fs').writeFileSync(${JSON.stringify(path.join(dir, 'b4.done'))}, 'finished'); S.finish(0, 300); } }, 2);
`);
  const b4 = spawn(process.execPath, [writer], { stdio: ['ignore', 'pipe', 'ignore'] });
  b4.stdout.once('data', () => b4.stdout.destroy());
  const b4rc = await new Promise((res) => b4.on('exit', (c, s) => res(c === null ? s : c)));
  t.check(b4rc === 0 && fs.existsSync(path.join(dir, 'b4.done')), 'a closed stdout (EPIPE) does not end fg: it finishes and exits 0 (B4)', String(b4rc));

  // B5: a run that is over but held by a handle exits with ITS code, the watchdog naming the handle
  const held = prog('held.js', `
const S = require(${JSON.stringify(path.join(__dirname, 'fg-supervisor.js'))});
setInterval(() => {}, 1000);
S.finish(3, 300);
`);
  const b5 = spawnSync(process.execPath, [held], { encoding: 'utf8', timeout: 5000 });
  t.check(b5.status === 3 && /held the exit for 0\.3 s: exiting/.test(b5.stderr), 'the exit watchdog names what held the exit and exits with fg\'s code (B5)', `${b5.status} ${b5.stderr}`);

  // B7: the sleep note reads the wall clock against the monotonic one
  const m = S.mark();
  t.check(S.sleptSecs(m) === 0 && S.sleptSecs({ wall: m.wall - 90000, mono: m.mono }) >= 89, 'sleptSecs is the wall clock beyond the monotonic clock (B7)');

  fs.rmSync(dir, { recursive: true, force: true });
  t.done();
})();

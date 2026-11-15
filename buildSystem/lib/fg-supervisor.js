'use strict';
// not-a-gate: fg's process supervisor — it runs programs and makes sure they end; the verdicts are its callers'
// fg-supervisor.js — how `fg` (Fizzygum/fg, buildSystem/fg-commit-point.js, buildSystem/fg-verbs.js) starts a program,
// waits for it, and makes sure that it and everything it started END. It knows nothing of legs, verdicts or verbs, so
// its cases (fg-supervisor-selftest.js) run it alone, with alarms in milliseconds.
//
// THE CONTRACT (docs/archive/fg-node-port-plan.md §4, rows A1–A13 and B1–B5, B9):
//   - a program's stdout and stderr are FILE DESCRIPTORS (a log file, or fg's own), never a Node pipe, so a program
//     that writes gigabytes costs no memory here (A6); a program gets no stdin unless its caller passes it on (A12);
//   - its end is its `exit` event, never `close` (a grandchild holding its output open must not hold fg, A8), and a
//     program that cannot start is an exit code, 127 when it is not found and 126 otherwise, with the reason in its
//     log (A7) — never a wait for an exit that will not come;
//   - its exit code is its own; killed by a signal it is 128 + the signal's number, and its log says which (A2);
//   - an ALARM, past which the whole TREE gets SIGTERM, then SIGKILL after a grace: the code is 142 (the code the
//     bash `perl -e 'alarm …'` gave, which scripts/lib/audited-suite.js reads as "killed, unmeasured"), and the log
//     says so (A3, A4); one outcome per run, and no signal ever goes to a pid after its own `exit` (A9);
//   - every descendant seen while the program ran that is still alive when it ends — the same pid AND the same start
//     time, so a reused pid is never signalled — is killed then (A5): a browser a runner left behind dies with it;
//   - fg's own ancestors and fg itself are never signalled.
// A "tree" is the program and its descendants, found by walking parent links in one `ps` snapshot, taken at the
// moment a kill is decided. Process GROUPS are not used (plan §9: puppeteer starts Chrome in a group of its own, and
// a person who kills fg's group must still kill its children).
//
// fg's OWN life (B1–B5): `guard()` installs the handlers — a signal stops new launches, kills every live tree and
// hands the signal to the caller's `onInterrupt` (its verdict says INTERRUPTED; a second signal kills at once), an
// error thrown in fg kills every live tree and hands the error to `onInternalError` (its verdict says INVALID) — and
// `out()` writes to stdout until stdout is gone (EPIPE: the run goes on, B4). `finish(code)` ends fg through its event
// loop, with a watchdog that names the handle still holding it and exits with the same code (B5).

const fs = require('fs');
const { spawn, spawnSync } = require('child_process');
const os = require('os');

const SIGNAL_NUMBER = os.constants.signals;
const ALARM_RC = 142;              // 128 + SIGALRM: what `perl -e 'alarm …'` left behind, read by audited-suite.js
const GRACE_MS = 5000;             // SIGTERM → SIGKILL
const TRACK_MS = 2000;             // how often a running program's descendants are recorded
const WATCHDOG_MS = 10000;         // how long a finished fg may wait for its event loop to drain

// ---- the process table ----------------------------------------------------------------------------------------------

// Map<pid, { pid, ppid, start }> — one `ps` snapshot. `start` is the process's start time as `ps` prints it (lstart,
// to the second), the identity that tells a live process from a later one given the same pid.
function snapshot() {
  // the C locale: `lstart` is the identity two fg processes compare, so it must not follow either one's locale; a
  // bounded wait: a stuck `ps` must not hold fg (a failed one is an empty table, and the alarm still kills the root
  // through its own handle, below)
  const r = spawnSync('ps', ['-A', '-o', 'pid=,ppid=,lstart='], { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024, timeout: 10000,
    env: { ...process.env, LC_ALL: 'C', LANG: 'C' } });
  const table = new Map();
  if (r.status !== 0 || typeof r.stdout !== 'string') return table;
  for (const line of r.stdout.split('\n')) {
    const m = /^\s*(\d+)\s+(\d+)\s+(.+?)\s*$/.exec(line);
    if (m) table.set(Number(m[1]), { pid: Number(m[1]), ppid: Number(m[2]), start: m[3] });
  }
  return table;
}
// every descendant of `pid` in `table`, nearest first
function descendantsOf(pid, table) {
  const children = new Map();
  for (const e of table.values()) {
    if (!children.has(e.ppid)) children.set(e.ppid, []);
    children.get(e.ppid).push(e);
  }
  const out = [], queue = [pid], seen = new Set([pid]);
  while (queue.length) {
    for (const c of children.get(queue.shift()) || []) {
      if (seen.has(c.pid)) continue;
      seen.add(c.pid); out.push(c); queue.push(c.pid);
    }
  }
  return out;
}
// fg itself and every ancestor of it: never signalled
function protectedPids(table) {
  const out = new Set([process.pid]);
  for (let e = table.get(process.pid); e && !out.has(e.ppid) && e.ppid > 0; e = table.get(e.ppid)) out.add(e.ppid);
  if (table.get(process.pid)) out.add(table.get(process.pid).ppid);
  return out;
}
const sameProcess = (e, table) => { const now = table.get(e.pid); return !!now && now.start === e.start; };
function alive(entry) { return sameProcess(entry, snapshot()); }

// Signal the entries still alive as the same process, except fg and its ancestors; the ones signalled.
function signalEntries(entries, sig, table = snapshot()) {
  const keep = protectedPids(table), hit = [];
  for (const e of entries) {
    if (keep.has(e.pid) || !sameProcess(e, table)) continue;
    try { process.kill(e.pid, sig); hit.push(e); } catch (err) { /* gone between the snapshot and the signal */ }
  }
  return hit;
}
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// SIGTERM to every entry, then SIGKILL after the grace to whichever is still the same process.
async function terminate(entries, graceMs = GRACE_MS) {
  if (!signalEntries(entries, 'SIGTERM').length) return;
  const until = Date.now() + graceMs;
  while (Date.now() < until) {
    await sleep(Math.min(200, graceMs));
    const table = snapshot();
    if (!entries.some((e) => sameProcess(e, table))) return;
  }
  signalEntries(entries, 'SIGKILL');
}

// ---- the registry of live programs, and fg's own state -------------------------------------------------------------

const live = new Set();          // the runs not yet settled
let spawnHook;                   // onSpawn(fn): fn({ pid, start }) for every program started, as it starts
let launching = true;            // false once fg was interrupted: nothing new starts
let interruptedBy;               // the signal that interrupted fg, once one did: the run's result is INTERRUPTED
let failedWith;                  // the error thrown in fg itself, once one was: the run's result is INVALID
let stdoutGone = false;

// out(text): fg's stdout, until it is gone (B4). err(text): its stderr, the same way.
function out(text) {
  if (stdoutGone) return;
  try { process.stdout.write(text); } catch (e) { stdoutGone = true; }
}
let stderrGone = false;
function err(text) {
  if (stderrGone) return;
  try { process.stderr.write(text); } catch (e) { stderrGone = true; }
}
process.stdout.on('error', (e) => { stdoutGone = true; if (e.code !== 'EPIPE') err('fg: stdout: ' + e.message + '\n'); });
process.stderr.on('error', () => { stderrGone = true; });

// A line in a run's log (its fd), or on stderr when it has none.
function note(fd, text) {
  if (typeof fd === 'number') { try { fs.writeSync(fd, text); return; } catch (e) { /* fall through to stderr */ } }
  err(text);
}

// ---- running one program ---------------------------------------------------------------------------------------------

// run({ argv, cwd, env, stdout, stderr, stdin, alarmSecs, alarmMs, graceMs, label })
//   stdout / stderr: a file descriptor (a number) or 'inherit' (fg's own); stdin: 'ignore' (default) or 'inherit'.
//   → Promise<{ rc, signal, timedOut, startError, pid }>. It never rejects.
function run(opts) {
  const argv = opts.argv;
  const label = opts.label || argv.join(' ');
  const logFd = typeof opts.stderr === 'number' ? opts.stderr : (typeof opts.stdout === 'number' ? opts.stdout : undefined);
  if (!launching) return Promise.resolve({ rc: 1, refused: true });
  return new Promise((resolve) => {
    let child;
    const record = { pid: undefined, root: undefined, seen: new Map(), settled: false, timedOut: false };
    const settle = (result) => {
      if (record.settled) return;
      record.settled = true;
      clearTimeout(record.alarm); clearInterval(record.tracker);
      live.delete(record);
      resolve(result);
    };
    try {
      child = spawn(argv[0], argv.slice(1), {
        cwd: opts.cwd, env: opts.env || process.env,
        stdio: [opts.stdin === 'inherit' ? 'inherit' : 'ignore', opts.stdout === undefined ? 'inherit' : opts.stdout,
          opts.stderr === undefined ? 'inherit' : opts.stderr],
      });
    } catch (e) {
      note(logFd, `fg: could not start ${argv[0]}: ${e.message}\n`);
      settle({ rc: e.code === 'ENOENT' ? 127 : 126, startError: e.message });
      return;
    }
    child.on('error', (e) => {
      if (record.settled) return;
      if (child.pid === undefined) {             // it never started: no exit event will come
        note(logFd, `fg: could not start ${argv[0]}: ${e.message}\n`);
        settle({ rc: e.code === 'ENOENT' ? 127 : 126, startError: e.message });
      } else note(logFd, `fg: ${label}: ${e.message}\n`);
    });
    if (child.pid === undefined) return;          // the error event settles it
    record.pid = child.pid;
    live.add(record);
    const remember = (table) => {
      const me = table.get(child.pid);
      if (me && !record.root) {
        record.root = me;
        if (spawnHook) { try { spawnHook(me); } catch (e) { /* the hook's own business */ } }
      }
      for (const d of descendantsOf(child.pid, table)) record.seen.set(d.pid + '@' + d.start, d);
    };
    remember(snapshot());
    record.tracker = setInterval(() => { if (!record.settled && !record.exited) remember(snapshot()); }, opts.trackMs || TRACK_MS);
    record.kill = async (graceMs) => {
      // the tree as it stands NOW (the program, unless it already exited, and its descendants), and every descendant
      // recorded earlier that is still the same process. The program itself is ALSO signalled through its own handle
      // (safe until Node reaps it, which is its exit): a snapshot that failed must not leave it running
      const table = snapshot();
      if (!record.exited) remember(table);
      const targets = [...record.seen.values()];
      if (!record.exited && record.root) targets.unshift(record.root);
      if (!record.exited) { try { child.kill('SIGTERM'); } catch (e) { /* exited meanwhile */ } }
      await terminate(targets, graceMs);
      if (!record.exited) {
        await sleep(graceMs === undefined ? GRACE_MS : graceMs);
        if (!record.exited) { try { child.kill('SIGKILL'); } catch (e) { /* exited meanwhile */ } }
      }
    };
    // (a timer holds at most 2^31-1 ms, about 24.8 days: a longer alarm is that one, never an overflow that fires at once)
    const alarmMs = Math.min(opts.alarmMs || (opts.alarmSecs > 0 ? opts.alarmSecs * 1000 : 0), 2147483647);
    if (alarmMs) {
      record.alarm = setTimeout(() => {
        if (record.exited || record.settled) return;
        record.timedOut = true;
        note(logFd, `fg: timed out after ${opts.alarmSecs || alarmMs / 1000} s — ${label}: its process tree was killed\n`);
        record.kill(opts.graceMs === undefined ? GRACE_MS : opts.graceMs);
      }, alarmMs);
    }
    child.on('exit', (code, signal) => {
      record.exited = true;                       // from here on, the program's own pid is never signalled
      clearTimeout(record.alarm); clearInterval(record.tracker);
      let rc;
      if (record.timedOut) rc = ALARM_RC;
      else if (code !== null) rc = code;
      else {
        rc = 128 + (SIGNAL_NUMBER[signal] || 0);
        note(logFd, `fg: ${label} was killed by ${signal}\n`);
      }
      // what it left behind: every descendant seen while it ran that is still the same process
      const leftovers = [...record.seen.values()];
      const finish = () => settle({ rc, signal: signal || undefined, timedOut: record.timedOut, pid: child.pid });
      if (!leftovers.length) return finish();
      const table = snapshot();
      const still = leftovers.filter((e) => sameProcess(e, table));
      if (!still.length) return finish();
      note(logFd, `fg: ${label} left ${still.length} process(es) behind: killed\n`);
      terminate(still, opts.graceMs === undefined ? GRACE_MS : opts.graceMs).then(finish, finish);
    });
  });
}

// ---- fg's own life ---------------------------------------------------------------------------------------------------

// Stop launching, and kill every live tree (each run then settles through its own exit).
async function killAll(graceMs = GRACE_MS) {
  launching = false;
  await Promise.all([...live].map((r) => (r.kill ? r.kill(graceMs) : undefined)));
}
function killAllNow() {
  launching = false;
  const table = snapshot();
  const targets = [];
  for (const r of live) { if (!r.exited && r.root) targets.push(r.root); targets.push(...r.seen.values()); }
  for (const r of live) for (const d of (r.pid ? descendantsOf(r.pid, table) : [])) targets.push(d);
  signalEntries(targets, 'SIGKILL', table);
}
const isLaunching = () => launching;
const onSpawn = (fn) => { spawnHook = fn; };
// the signal that interrupted fg, and the exit code it means (128 + its number); undefined when none did
const interrupted = () => interruptedBy;
const interruptedRc = () => (interruptedBy ? 128 + SIGNAL_NUMBER[interruptedBy] : undefined);
// an error thrown in fg seals the run as INVALID (the dispatcher's own catch calls fail() too)
const failed = () => failedWith;
const fail = (e) => { if (!failedWith) failedWith = e || new Error('fg internal error'); launching = false; };

// guard({ onInterrupt(signal) → Promise<rc>, onInternalError(error) → Promise<rc> })
let guarded = false;
function guard({ onInterrupt, onInternalError }) {
  if (guarded) return;
  guarded = true;
  let stopping = false;
  for (const sig of ['SIGINT', 'SIGTERM', 'SIGHUP', 'SIGQUIT']) {
    process.on(sig, () => {
      if (stopping) {                              // a second signal: kill at once, exit at once
        killAllNow();
        process.exit(128 + SIGNAL_NUMBER[sig]);
      }
      stopping = true;
      launching = false;
      interruptedBy = sig;
      err(`\nfg: ${sig} — stopping: no new program starts; every running one is being killed\n`);
      killAll().then(() => onInterrupt(sig), () => onInterrupt(sig))
        .then((rc) => finish(rc === undefined ? 128 + SIGNAL_NUMBER[sig] : rc),
          () => finish(128 + SIGNAL_NUMBER[sig]));
    });
  }
  const internal = (e) => {
    if (stopping) return;
    stopping = true;
    launching = false;
    failedWith = e;
    err(`fg: internal error: ${e && e.stack ? e.stack : e}\n`);
    killAll().then(() => onInternalError(e), () => onInternalError(e))
      .then((rc) => finish(rc === undefined ? 2 : rc), () => finish(2));
  };
  process.on('uncaughtException', internal);
  process.on('unhandledRejection', internal);
}

// End fg with `code` through its event loop (so a large final write is never lost); a watchdog names whatever still
// holds the loop and exits with the same code (B5).
let finishing = false;
// The FIRST code given is fg's: a later finish (main's result after an interrupt or an internal error) cannot overwrite it.
function finish(code, watchdogMs = WATCHDOG_MS) {
  if (finishing) return;
  finishing = true;
  process.exitCode = code;
  const dog = setTimeout(() => {
    const held = (process._getActiveHandles ? process._getActiveHandles() : [])
      .filter((h) => h !== dog && !(h && h.constructor && /WriteStream|ReadStream|TTY/.test(h.constructor.name)))
      .map((h) => (h && h.constructor ? h.constructor.name : typeof h));
    err(`fg: the run is over (exit ${code}) but ${held.length ? held.join(', ') : 'a handle'} held the exit for ` +
      `${watchdogMs / 1000} s: exiting\n`);
    process.exit(code);
  }, watchdogMs);
  dog.unref();
}

// Sleep detection (B7): wall-clock seconds beyond the monotonic clock since `mark()`. macOS's monotonic clock stops
// while the machine sleeps; the wall clock does not.
const mark = () => ({ wall: Date.now(), mono: process.hrtime.bigint() });
const sleptSecs = (m) => Math.max(0, Math.round((Date.now() - m.wall) / 1000 - Number(process.hrtime.bigint() - m.mono) / 1e9));

module.exports = { snapshot, descendantsOf, protectedPids, signalEntries, alive, terminate, run, killAll, killAllNow, isLaunching, interrupted, interruptedRc,
  failed, fail, onSpawn, guard,
  finish, out, err, note, mark, sleptSecs, ALARM_RC, GRACE_MS };

'use strict';
// not-a-gate: fg's commit-point half (the build, the lint, the suite, the leg runner, the waves, the retry) — the programs it launches are the gates
// fg-commit-point.js — what `fg presuite` and `fg gauntlet` run, and the pieces the other verbs share with them:
// the verdict files, the banners, the build, the lint, the suite, ONE leg (run_leg), a WAVE of legs at once, the serial
// retry of a failed leg and the tally. Fizzygum/fg is the entry point; its on-demand verbs live in fg-verbs.js, apart,
// so that lib/what-runs.js, which takes THIS module as the commit point's root (what it launches, through path.join,
// and the leg table it requires), does not count their tools as run at a commit point. How a program is started, timed
// out and made to end is lib/fg-supervisor.js's; this module knows only what to start and what its result means.
//
// EQUAL to the bash fg it replaced (docs/archive/fg-node-port-plan.md §3), byte for byte where a reader depends on it:
// the verdict lines (`/tmp/fg-<cmd>.verdict`: `RUNNING since <date> pid=<pid> load=<n>[ ⚠load≥cores]`, then
// `<CMD> EXIT=<rc> <text> (<date>)`), the `PENDING` stamp of a leg log, the `fg-leg: <name> rc=<rc> <n>s` stamp, the
// banners, the tally (`<leg>:PASS(<n>s)`, `PASS-serial-only`, `INFRA-FLAKE`, `FAIL`, `NEVER-RAN`), the order of
// everything (lint before build, waves in order, a wave's legs waited for in launch order, the retries after the last
// wave) and every program launched, its arguments, its cwd, its alarm and the `FG_*`/`FIZZYGUM_*` it sees. Two shard
// counts behave as bash's SHELL variables did: fg sets `FG_SUITE_SHARDS` / `FG_GATE_SHARDS` for its own placeholders,
// and a program sees them only when fg's caller had exported them.
// BETTER where the plan's §5 says so (each its own ruling): a leg leaves no process behind and its log names a signal or
// a timeout; an interrupted run says INTERRUPTED and kills its children; an error in fg is INVALID (exit 2); a closed
// stdout no longer ends the run; a second long operation is refused while one runs; a leg that slept says so; a verdict
// is written whole (to a temporary file, then renamed); the build has a ceiling (FG_BUILD_ALARM_SECS, default 1800 s).
//
// TEST RAILS, accepted only with FG_TEST_RAILS=1 (else fg refuses to start): FG_TMP=<dir> in place of /tmp,
// FG_LEGS_TABLE=<file> in place of buildSystem/legs.js, FG_CENSUS_LOG=<file> (one JSON line per program started: its
// argv, cwd, alarm and the FG_*/FIZZYGUM_* it sees).

const fs = require('fs');
const os = require('os');
const path = require('path');
const { StringDecoder } = require('string_decoder');
const sup = require('./lib/fg-supervisor');

const FZ = path.resolve(__dirname, '..');
const ROOT = path.dirname(FZ);
const FT = path.join(ROOT, 'Fizzygum-tests');

// ---- the rails ---------------------------------------------------------------------------------------------------------
const RAILS = ['FG_TMP', 'FG_LEGS_TABLE', 'FG_CENSUS_LOG'];
function railsRefusal() {
  const set = RAILS.filter((r) => process.env[r] !== undefined);
  if (set.length && process.env.FG_TEST_RAILS !== '1') return `fg: ${set.join(', ')} is a test rail, refused outside a test (FG_TEST_RAILS=1)`;
  return undefined;
}
const TMP = process.env.FG_TEST_RAILS === '1' && process.env.FG_TMP ? process.env.FG_TMP : '/tmp';
const tmp = (name) => path.join(TMP, name);
// The leg table, loaded under a guard: one that cannot even load (a syntax error, a bad FG_LEGS_TABLE) is a table fg
// cannot run — `presuite` and `gauntlet` REFUSE it with their verdict (B12), and every other verb still works — never
// a crash before a verdict, which would leave the previous run's verdict standing.
function loadTable() {
  try { return process.env.FG_TEST_RAILS === '1' && process.env.FG_LEGS_TABLE ? require(path.resolve(process.env.FG_LEGS_TABLE)) : require('./legs'); }
  catch (e) {
    const why = `the table cannot be loaded: ${e.message.split('\n')[0]}`;
    return { LEGS: [], tableErrors: () => [why], legsIn: () => [], legNamed: () => { throw new Error(why); }, roster: () => [`  (fg: ${why})`] };
  }
}
const L = loadTable();

// ---- the shell's variables, as bash had them (C3) ------------------------------------------------------------------
// `vars` is what fg reads (`${FG_SUITE_SHARDS:-4}`); a program sees a variable fg SET only if fg's caller exported it.
const exported = new Set(Object.keys(process.env));
const vars = { ...process.env };
function setVar(name, value) { vars[name] = value; }
// the environment a program gets: fg's own, with the exported variables fg set, and `extra` (a subshell's exports)
function childEnv(extra = {}) {
  const env = { ...process.env };
  for (const k of exported) if (vars[k] !== undefined) env[k] = vars[k];
  return Object.assign(env, extra);
}
const shellVar = (name, extra) => (extra && extra[name] !== undefined ? extra[name] : vars[name]);

// ---- output --------------------------------------------------------------------------------------------------------------
const out = (s) => sup.out(s);
const say = (s) => out(s + '\n');
const ban = (text) => out('\n================================ ' + text + ' ================================\n');
const pad2 = (n) => String(n).padStart(2, '0');
function stamp(d = new Date()) {
  return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())} ${pad2(d.getHours())}:${pad2(d.getMinutes())}:${pad2(d.getSeconds())}`;
}
const seconds = () => Math.floor(Date.now() / 1000);

// ---- reading logs: line by line, never whole (A11) -----------------------------------------------------------------------
function forEachLine(file, fn) {
  return new Promise((resolve) => {
    let rest = '', n = 0, stopped = false;
    const dec = new StringDecoder('utf8');
    const s = fs.createReadStream(file);
    const stop = () => { stopped = true; s.destroy(); resolve(); };
    s.on('data', (chunk) => {
      const lines = (rest + dec.write(chunk)).split('\n');
      rest = lines.pop();
      for (const l of lines) { if (fn(l, ++n) === false) return stop(); }
    });
    s.on('end', () => { if (!stopped) { rest += dec.end(); if (rest.length) fn(rest, ++n); resolve(); } });
    s.on('error', () => resolve());
  });
}
// the last `k` lines matching `re` (grep -E … | tail -k), each "<n>:" prefixed when `numbered` (grep -n)
async function grepLast(file, re, k, numbered = false) {
  const kept = [];
  await forEachLine(file, (l, n) => { if (re.test(l)) { kept.push(numbered ? n + ':' + l : l); if (kept.length > k) kept.shift(); } });
  return kept;
}
async function fileHas(file, test) {
  let found = false;
  await forEachLine(file, (l) => { if (test(l)) { found = true; return false; } return true; });
  return found;
}
// the last `n` lines of a file, as `tail -n` prints them (a last line with no newline stays without one), read from
// the end of the file
function tailText(file, n) {
  let fd;
  try { fd = fs.openSync(file, 'r'); } catch (e) { return ''; }
  try {
    const size = fs.fstatSync(fd).size;
    let pos = size, buf = Buffer.alloc(0);
    const want = n + 1;
    while (pos > 0) {
      const len = Math.min(65536, pos);
      pos -= len;
      const chunk = Buffer.alloc(len);
      fs.readSync(fd, chunk, 0, len, pos);
      buf = Buffer.concat([chunk, buf]);
      let count = 0;
      for (let i = buf.length - 2; i >= 0; i--) if (buf[i] === 10 && ++count >= want - 1) { buf = buf.slice(i + 1); pos = 0; break; }
    }
    return buf.toString('utf8');
  } finally { fs.closeSync(fd); }
}
const outTail = (file, n) => out(tailText(file, n));

// ---- launching -------------------------------------------------------------------------------------------------------------
// launch(argv, { cwd, alarmSecs, stdout, stderr, stdin, extra }) → rc: one program, through the supervisor, recorded in
// the census when its rail is set.
async function launch(argv, opts = {}) {
  const env = opts.env || childEnv(opts.extra);
  if (process.env.FG_TEST_RAILS === '1' && process.env.FG_CENSUS_LOG) {
    const seen = {};
    for (const k of Object.keys(env).sort()) if (/^(FG|FIZZYGUM)_/.test(k) && !RAILS.includes(k) && k !== 'FG_TEST_RAILS') seen[k] = env[k];
    fs.appendFileSync(process.env.FG_CENSUS_LOG, JSON.stringify({ argv, cwd: opts.cwd || process.cwd(), alarm: opts.alarmSecs || 0, env: seen }) + '\n');
  }
  const r = await sup.run({ argv, cwd: opts.cwd, env, alarmSecs: opts.alarmSecs, stdout: opts.stdout, stderr: opts.stderr,
    stdin: opts.stdin || 'ignore', label: opts.label });
  return r.rc;
}
// a program's stdout, kept in a file of fg's temp directory (a small output: a profile, a list of names)
async function capture(argv, opts = {}) {
  const file = tmp(`fg-capture-${process.pid}-${Math.random().toString(36).slice(2)}.txt`);
  const fd = fs.openSync(file, 'w');
  let rc;
  try { rc = await launch(argv, { ...opts, stdout: fd, stderr: opts.stderr === undefined ? 'inherit' : opts.stderr }); }
  finally { fs.closeSync(fd); }
  const text = fs.readFileSync(file, 'utf8');
  fs.rmSync(file, { force: true });
  return { rc, text };
}
const openLog = (file, flags) => fs.openSync(file, flags);
async function withLog(file, flags, fn) {
  const fd = openLog(file, flags);
  try { return await fn(fd); } finally { fs.closeSync(fd); }
}

// kill_browsers: GLOBAL to the machine — the fallback for what an earlier run left behind
// (`extra`: the leg's exports, which a kill inside a leg sees as bash's did)
async function killBrowsers(extra) {
  if (!sup.isLaunching()) return;
  await launch(['pkill', '-9', '-f', 'Chrome for Testing|chrome-headless|puppeteer|webkit'], { stdout: 'ignore', stderr: 'ignore', extra });
  await new Promise((r) => setTimeout(r, 1000));
}

// ---- verdicts ----------------------------------------------------------------------------------------------------------
// written whole: a temporary file, then a rename (B9); a verdict that cannot be written is a warning, never an exit code (B8)
function writeVerdict(cmd, line) {
  const file = tmp(`fg-${cmd}.verdict`), part = file + '.' + process.pid + '.part';
  try { fs.writeFileSync(part, line + '\n'); fs.renameSync(part, file); }
  catch (e) { sup.err(`fg: warning — could not write ${file}: ${e.message}\n`); try { fs.rmSync(part, { force: true }); } catch (e2) { /* nothing */ } }
}
let caffeinated = false;
const openVerdicts = new Set();
// verdictStart(cmd): keep the machine awake for fg's life, read the load, stamp RUNNING, and note who runs it
// (`/tmp/fg-<cmd>.running`: fg's pid and start time, so `fg status` can tell a dead run from a live one, B2)
function verdictStart(cmd) {
  if (!caffeinated && onPath('caffeinate')) {
    caffeinated = true;
    if (process.env.FG_TEST_RAILS === '1' && process.env.FG_CENSUS_LOG) {
      fs.appendFileSync(process.env.FG_CENSUS_LOG, JSON.stringify({ argv: ['caffeinate', '-dims', '-w', String(process.pid)], cwd: process.cwd(), alarm: 0, env: {} }) + '\n');
    }
    try {
      const c = require('child_process').spawn('caffeinate', ['-dims', '-w', String(process.pid)], { stdio: 'ignore' });
      c.on('error', () => {});
      c.unref();
    } catch (e) { /* no caffeinate: the run goes on */ }
  }
  const load = os.loadavg()[0].toFixed(2), cores = os.cpus().length;
  let warn = '';
  if (Math.floor(Number(load)) >= cores) {
    warn = ' ⚠load≥cores';
    ban(`⚠ PRE-FLIGHT: 1-min loadavg ${load} ≥ ${cores} cores — a parallel run on a busy machine yields INFRA-FLAKE legs and false FAILs (2026-08-04 lesson: 7 h gauntlet, wasted night); consider waiting, or FG_GAUNTLET_SERIAL=1`);
  }
  writeVerdict(cmd, `RUNNING since ${stamp()} pid=${process.pid} load=${load}${warn}`);
  markRunning(cmd);
  openVerdicts.add(cmd);
}
// Once a signal interrupted fg, every verdict it writes says so: the run did not finish, whatever its programs said;
// once fg itself failed, every verdict is INVALID (nothing it measured after that is a result).
function verdictEnd(cmd, rc, text) {
  if (sup.interrupted()) { rc = sup.interruptedRc(); text = `INTERRUPTED by ${sup.interrupted()}`; }
  else if (sup.failed()) { const e = sup.failed(); rc = 2; text = `INVALID — fg internal error: ${e && e.message ? e.message : e}`; }
  writeVerdict(cmd, `${cmd.toUpperCase()} EXIT=${rc} ${text} (${stamp()})`);
  openVerdicts.delete(cmd);
}
function onPath(prog) {
  for (const d of (process.env.PATH || '').split(':')) {
    try { fs.accessSync(path.join(d || '.', prog), fs.constants.X_OK); return true; } catch (e) { /* next */ }
  }
  return false;
}

// ---- who runs: `/tmp/fg-<cmd>.<pid>.running` and the long-operation lock -----------------------------------------------
// A long operation's `.running` file names fg (its pid and start time; the pid is also in the file's name and in its
// RUNNING verdict) and every program it launched (a `child=` line each, appended as it starts): `fg status` tells a
// RUNNING verdict whose fg is gone (STALE, B2), and `fg killz` kills what such a run left behind. One file per fg
// process, so two runs of one verb (FG_ALLOW_CONCURRENT=1) never share one. The files go when fg ends; after a SIGKILL
// they stay, which is how the dead run is told.
const ownRunning = new Set();
const runningFile = (cmd, pid = process.pid) => tmp(`fg-${cmd}.${pid}.running`);
function markRunning(cmd) {
  if (ownRunning.has(cmd)) return;
  const me = sup.snapshot().get(process.pid);
  try { fs.writeFileSync(runningFile(cmd), `pid=${process.pid} start=${me ? me.start : ''}\n`); ownRunning.add(cmd); }
  catch (e) { sup.err(`fg: warning — could not write ${runningFile(cmd)}: ${e.message}\n`); }
}
sup.onSpawn((e) => {
  for (const cmd of ownRunning) { try { fs.appendFileSync(runningFile(cmd), `child=${e.pid} start=${e.start}\n`); } catch (err) { /* nothing */ } }
});
// a `.running` file as { cmd, pid, start, children: [{ pid, start }] }
function readRunning(name) {
  let text;
  try { text = fs.readFileSync(path.join(TMP, name), 'utf8'); } catch (e) { return undefined; }
  const head = /^pid=(\d+) start=(.*)$/m.exec(text);
  if (!head) return undefined;
  const children = [...text.matchAll(/^child=(\d+) start=(.*)$/gm)].map((m) => ({ pid: Number(m[1]), start: m[2] }));
  return { cmd: name.slice(3).replace(/\.\d+\.running$/, ''), pid: Number(head[1]), start: head[2], children };
}
const runningFiles = () => { try { return fs.readdirSync(TMP).filter((n) => /^fg-.+\.\d+\.running$/.test(n)); } catch (e) { return []; } };
// The programs dead fg runs left behind (every recorded child still the same process, with its descendants now),
// killed: TERM, then KILL after the grace. A live run's are never touched. → the runs, as "<cmd> (pid <pid>)", and the count.
async function killStaleRuns() {
  const table = sup.snapshot(), runs = [], targets = [];
  for (const n of runningFiles()) {
    const r = readRunning(n);
    if (!r || r.pid === process.pid) continue;
    const owner = table.get(r.pid);
    if (owner && owner.start === r.start) continue;
    const alive = r.children.filter((c) => { const e = table.get(c.pid); return e && e.start === c.start; });
    if (!alive.length) continue;
    runs.push(`${r.cmd} (pid ${r.pid})`);
    for (const c of alive) targets.push(c, ...sup.descendantsOf(c.pid, table));
  }
  if (targets.length) await sup.terminate(targets);
  return { runs, count: targets.length };
}

// B6: ONE long operation (one that builds or launches a browser) at a time. The lock is created exclusively
// (`/tmp/fg-long-operation.lock`: its owner's pid, start time and verb), so two starting together cannot both pass; a
// lock whose owner is gone (a killed fg) is taken over. FG_ALLOW_CONCURRENT=1 skips it.
const LOCK = () => tmp('fg-long-operation.lock');
let lockHeld = false;
// acquireLongOp(cmd, keepsVerdict) → true, or false (refused: it said why, and wrote `REFUSED` in the verb's verdict when
// the verb keeps one and the live run is another verb — the live run's RUNNING line is not this run's to overwrite).
// A lock whose owner is gone is taken over, after the programs that dead run left behind are killed: its runners would
// otherwise go on writing into the logs this run is about to write.
async function acquireLongOp(cmd, keepsVerdict) {
  if (process.env.FG_ALLOW_CONCURRENT === '1') return true;
  const me = sup.snapshot().get(process.pid);
  for (let attempt = 0; attempt < 20; attempt++) {
    try {
      const fd = fs.openSync(LOCK(), 'wx');
      fs.writeSync(fd, `pid=${process.pid} start=${me ? me.start : ''} cmd=${cmd}\n`);
      fs.closeSync(fd);
      lockHeld = true;
      return true;
    } catch (e) {
      if (e.code !== 'EEXIST') { sup.err(`fg: warning — no long-operation lock (${e.message}); going on\n`); return true; }
    }
    let text;
    try { text = fs.readFileSync(LOCK(), 'utf8'); } catch (e) { continue; }   // released meanwhile
    const m = /^pid=(\d+) start=(.*) cmd=(.*)$/m.exec(text);
    if (!m) { await new Promise((r) => setTimeout(r, 100)); continue; }        // one being created: its owner writes it next
    const owner = sup.snapshot().get(Number(m[1]));
    if (owner && owner.start === m[2]) {
      sup.err(`fg ${cmd}: REFUSED — another fg long operation is running: ${m[3]} (pid ${m[1]}). ` +
        'Two at once share the build tree and kill each other\'s browsers. Wait for it, or set FG_ALLOW_CONCURRENT=1.\n');
      if (keepsVerdict && m[3] !== cmd) writeVerdict(cmd, `${cmd.toUpperCase()} EXIT=2 REFUSED — another fg long operation was running: ${m[3]} (pid ${m[1]}) (${stamp()})`);
      return false;
    }
    const stale = await killStaleRuns();
    if (stale.count) sup.err(`fg: killed ${stale.count} process(es) that a dead fg run left behind: ${stale.runs.join(', ')}\n`);
    try { if (fs.readFileSync(LOCK(), 'utf8') === text) fs.rmSync(LOCK(), { force: true }); } catch (e) { /* another fg took it over first */ }
  }
  sup.err(`fg ${cmd}: REFUSED — the long-operation lock ${LOCK()} could not be taken.\n`);
  return false;
}
// every `.running` file this fg wrote, and its lock: gone when it ends
function releaseAll() {
  for (const cmd of ownRunning) { try { fs.rmSync(runningFile(cmd), { force: true }); } catch (e) { /* nothing */ } }
  ownRunning.clear();
  if (lockHeld) {
    try { if (new RegExp(`^pid=${process.pid} `).test(fs.readFileSync(LOCK(), 'utf8'))) fs.rmSync(LOCK(), { force: true }); } catch (e) { /* nothing */ }
    lockHeld = false;
  }
}

// ---- the leg table, as fg reads it ---------------------------------------------------------------------------------------
// { names } or { error }: a table fg cannot run refuses the run before anything is built (B12)
function tableNames(where) {
  const errors = L.tableErrors();
  if (errors.length) return { error: 'legs.js: the leg table cannot be run:\n  ' + errors.join('\n  ') };
  try {
    const names = L.legsIn(where);
    // a list of legs to RUN holds at least one leg; the infra list may be empty (no leg's exit 3 is an infra flake)
    if ((!names.length && where !== 'infra') || names.some((n) => !/^[a-z0-9-]+$/.test(n))) return { error: 'legs.js: no legs in ' + JSON.stringify(where) };
    return { names };
  } catch (e) { return { error: 'legs.js: ' + e.message }; }
}

// ---- the build ---------------------------------------------------------------------------------------------------------
const BUILD_SUMMARY = /selftests\] (OK|FAIL)|syntax check:|layering gate|dead-methods\]|unresolved-sends\]|call-separation\]|stinks\] (OK|FAIL)|thin-wraps\] (OK|FAIL)|test \.js syntax|aim-census\] (OK|FAIL)/;
// fg_build [flags]: build in Fizzygum/, gate on the REAL exit + done!!! + 0 violations; a ceiling past which the build
// is killed (B11)
async function fgBuild(flags = []) {
  const log = tmp('fg-build.log');
  const ceiling = process.env.FG_BUILD_ALARM_SECS === undefined ? 1800 : Number(process.env.FG_BUILD_ALARM_SECS);
  // `./build_it_please.sh` from Fizzygum/, as bash ran it (the build is lib/what-runs.js's root of its own)
  const rc = await withLog(log, 'w', (fd) => launch(['./build_it_please.sh', ...flags],
    { cwd: FZ, stdout: fd, stderr: fd, alarmSecs: ceiling > 0 ? ceiling : 0, label: 'the build' }));
  if (stopped()) return 1;                       // interrupted: the caller says INTERRUPTED, not BUILD FAILED
  for (const l of await grepLast(log, BUILD_SUMMARY, 10)) say(l);
  if (rc !== 0 || !(await fileHas(log, (l) => l.includes('done!!!')))) {
    ban(`BUILD FAILED (exit ${rc}, no done!!!)`); outTail(log, 20); return 1;
  }
  if (await fileHas(log, (l) => /[1-9][0-9]* violation/.test(l))) {
    ban('LINT VIOLATION'); for (const l of await grepLast(log, /violation|\[[A-F]\]/, 20, true)) say(l); return 1;
  }
  say('  build OK — 0 violations, done!!!');
  return 0;
}

// A tier that RUNS THE SUITE must build a tree that ships the harness page: the profile is asked first, through the
// one reader of profiles, and nothing is built otherwise. 0, or 2 (nothing was measured).
async function suiteProfileOrRefuse(flags) {
  const r = await capture(['node', './' + path.join('buildSystem', 'lib', 'profile.js'), '--shell', ...flags], { cwd: FZ });
  if (r.rc !== 0) { say('fg: could not read the build profile — nothing was built.'); return 2; }
  const value = (k) => { const m = new RegExp('^' + k + '=(.*)$', 'm').exec(r.text); return m ? m[1] : ''; };
  if (value('PROFILE_SHIPS_HARNESS_ENTRY') === 'true') return 0;
  say(`fg: profile '${value('PROFILE_NAME')}' ships no harness page, so the suite cannot run on it — nothing was built. Use the default (dev) profile; for a boot check of this one, build_and_smoke.sh (or fg homepage).`);
  return 2;
}

// fg_suite [flags]: the headless suite vs the current build ("$@" first, so a caller's --shards=N wins over the 8). In a
// parallel wave (FG_PARALLEL=1) no browser is killed: the wave killed them once, up front.
async function fgSuite(flags, opts = {}) {
  if (shellVar('FG_PARALLEL', opts.extra) !== '1') await killBrowsers(opts.extra);
  return launch(['node', path.join('scripts', 'run-all-headless.js'), ...flags, '--shards=8'],
    { cwd: FT, alarmSecs: 900, stdout: opts.fd, stderr: opts.fd, stdin: opts.stdin, extra: opts.extra, label: 'the suite' });
}

// ---- the lint ----------------------------------------------------------------------------------------------------------
// fg lint: PRE-BUILD static checks in ~2 s over git-CHANGED files: `node --check` on each changed test or script .js;
// the CoffeeScript syntax gate when any .coffee changed; the macro source-discipline gate when tests/ moved.
const lastField = (l) => { const f = l.trim().split(/\s+/); return f[f.length - 1] || ''; };
async function changedPaths(repo) {
  const r = await capture(['git', '-C', repo, 'status', '--porcelain'], { stderr: 'ignore' });
  return r.text.split('\n').filter((l) => l.length).map(lastField);
}
async function runLint() {
  const t0 = seconds();
  let bad = false;
  const tjs = (await changedPaths(FT)).filter((f) => /^(tests|scripts)\/.*\.js$/.test(f));
  for (const f of tjs) {
    if (!fs.existsSync(path.join(FT, f)) || !fs.statSync(path.join(FT, f)).isFile()) continue;
    const errFile = tmp('fg-lint-err.txt');
    const rc = await withLog(errFile, 'w', (fd) => launch(['node', '--check', path.join(FT, f)], { stderr: fd }));
    if (stopped()) return 1;                     // interrupted: no false syntax error
    if (rc !== 0) {
      say(`✗ fg lint: JS syntax error in Fizzygum-tests/${f}`);
      for (const l of tailHead(errFile, 8)) say('    ' + l);
      bad = true;
    }
  }
  const coffee = [...await changedPaths(FZ), ...await changedPaths(FT)].filter((f) => /\.coffee$/.test(f)).length;
  if (coffee > 0) {
    const log = tmp('fg-lint-coffee.log');
    const rc = await withLog(log, 'w', (fd) => launch(['node', path.join('buildSystem', 'check-coffee-syntax.js')], { cwd: FZ, stdout: fd, stderr: fd }));
    if (stopped()) return 1;
    if (rc !== 0) { say('✗ fg lint: CoffeeScript syntax gate FAILED:'); outTail(log, 10); bad = true; }
  }
  if (tjs.some((f) => f.startsWith('tests/'))) {
    const log = tmp('fg-lint-macrosrc.log');
    const rc = await withLog(log, 'w', (fd) => launch(['node', path.join('scripts', 'check-macro-source-discipline.js')], { cwd: FT, stdout: fd, stderr: fd }));
    if (stopped()) return 1;
    if (rc !== 0) { say('✗ fg lint: macro source-discipline gate FAILED:'); for (const l of tailHead(log, 12)) say('    ' + l); bad = true; }
  }
  if (!bad) { say(`  lint OK (${seconds() - t0}s — ${tjs.length} changed test/script .js checked, coffee gate ${coffee > 0 ? 'run' : 'skipped'})`); return 0; }
  ban('FG LINT FAILED');
  return 1;
}
// the first `n` lines of a small file (sed … | head -n)
function tailHead(file, n) {
  let text = '';
  try { text = fs.readFileSync(file, 'utf8'); } catch (e) { return []; }
  const lines = text.split('\n');
  if (lines[lines.length - 1] === '') lines.pop();
  return lines.slice(0, n);
}

// ---- one leg ---------------------------------------------------------------------------------------------------------
const slept = new Map();     // leg → seconds the machine slept while it ran (B7)
// legs_pending <cmd> <leg…>: every leg log stamped PENDING at run start
function legsPending(cmd, names) {
  for (const l of names) {
    try {
      fs.writeFileSync(tmp(`fg-${l}.log`), `PENDING — ${cmd} started ${stamp()} pid=${process.pid}; leg '${l}' has not run yet.\n` +
        '(stamped at run start; replaced by real output when the leg begins. If you are reading THIS,\n' +
        ' the leg is still queued — do not read anything into it.)\n');
    } catch (e) { sup.err(`fg: warning — could not stamp ${tmp(`fg-${l}.log`)}: ${e.message}\n`); }
  }
}
const expand = (w) => String(w).split('{SUITE_SHARDS}').join(vars.FG_SUITE_SHARDS || '4').split('{GATE_SHARDS}').join(vars.FG_GATE_SHARDS || '6');
// run_leg <name> → its exit code: ONE leg into /tmp/fg-<name>.log, its row's steps in order, the first failing step
// ending it; `extra` is a wave's subshell exports. It never throws: a thrown error is exit 1, its message in the log (A13).
async function runLeg(name, extra = {}) {
  const lg = tmp(`fg-${name}.log`);
  const t0 = seconds(), clock = sup.mark();
  const images = tmp(`fg-${name}.failure-images`);
  let rc = 1, fd;
  try { fs.rmSync(images, { recursive: true, force: true }); } catch (e) { /* B8: the leg says so below if it matters */ }
  try { fd = fs.openSync(lg, 'w'); }
  catch (e) { sup.err(`fg: leg ${name}: its log ${lg} cannot be opened: ${e.message}\n`); return 1; }
  try {
    const errors = L.tableErrors();
    let row;
    if (errors.length) fs.writeSync(fd, 'run_leg: legs.js: the leg table cannot be run:\n  ' + errors.join('\n  ') + '\n');
    else { try { row = L.legNamed(name); } catch (e) { fs.writeSync(fd, 'run_leg: legs.js: ' + e.message + '\n'); } }
    if (row) {
      rc = 0;
      const legExtra = { ...extra, FIZZYGUM_FAILURE_IMAGES_DIR: images };
      let steps = 0;
      for (const s of row.steps) {
        steps++;
        if (s.suite) rc = await fgSuite(s.suite.map(expand), { fd, extra: legExtra });
        else {
          const cwd = expand(s.cwd) === 'fizzygum' ? FZ : FT;
          rc = await launch(['node', expand(s.script), ...s.args.map(expand)],
            { cwd, alarmSecs: Number(expand(s.alarm)), stdout: fd, stderr: fd, extra: legExtra, label: `leg ${name}: ${s.script}` });
        }
        if (rc !== 0) break;
      }
      if (!steps) { fs.writeSync(fd, `run_leg: the leg table gave no step for ${name}\n`); rc = 1; }
      // a leg whose program also prints its verdict passes only with that line in its log; any other end of it is 1
      if (row.passLine && (rc !== 0 || !(await fileHas(lg, (l) => l.includes(row.passLine))))) rc = 1;
    }
  } catch (e) {
    try { fs.writeSync(fd, `fg: leg ${name}: fg itself failed: ${e && e.stack ? e.stack : e}\n`); } catch (e2) { /* nothing */ }
    rc = 1;
  }
  const z = sup.sleptSecs(clock);
  if (z > 60) { slept.set(name, z); try { fs.writeSync(fd, `fg: the machine slept about ${z} s while this leg ran (its wall-clock time ran past its monotonic time)\n`); } catch (e) { /* nothing */ } }
  else slept.delete(name);
  try { fs.writeSync(fd, `fg-leg: ${name} rc=${rc} ${seconds() - t0}s\n`); } catch (e) { /* nothing */ }
  fs.closeSync(fd);
  // refresh the leg's STANDALONE verdict, only if one exists
  if (fs.existsSync(tmp(`fg-${name}.verdict`))) verdictEnd(name, rc, `${rc === 0 ? 'OK' : rc === 2 ? 'INVALID' : rc === 3 ? 'INFRA-FLAKE' : 'FAILED'} (gauntlet leg)`);
  return rc;
}
async function legSecs(name) {
  const kept = await grepLast(tmp(`fg-${name}.log`), /^fg-leg: .* rc=[0-9]* ([0-9]*s)$/, 1);
  return kept.length ? /([0-9]*s)$/.exec(kept[0])[1] : '';
}
async function legHeadline(name) {
  let re;
  try { re = new RegExp(L.legNamed(name).headline); } catch (e) { return; }
  for (const l of await grepLast(tmp(`fg-${name}.log`), re, 2)) say('    ' + l);
}
const sleptNote = (name) => (slept.has(name) ? `, slept ${slept.get(name)}s` : '');

// ---- a run: its waves, its retry, its tally ---------------------------------------------------------------------------
function newRun(infra) { return { res: [], tally: '', ok: true, warn: false, infra: new Set(infra) }; }
// run_wave <legs…>: every leg at once, browsers not culled; each waited for in launch order
async function runWave(run, names) {
  const extra = { FIZZYGUM_KEEP_STALE_BROWSERS: '1', FG_PARALLEL: '1' };
  const running = names.map((n) => runLeg(n, extra).catch(() => 1));
  for (let i = 0; i < names.length; i++) {
    const rc = await running[i];
    run.res.push([names[i], rc]);
    say(`--- ${names[i]} (rc=${rc}, ${await legSecs(names[i])}) ---`);
    await legHeadline(names[i]);
  }
}
// collect_and_retry: a passed leg tallies; a failed one gets ONE serial retry, alone
async function collectAndRetry(run) {
  for (const [n, rc] of run.res) {
    if (stopped()) return;
    if (rc === 0) { run.tally += ` ${n}:PASS(${await legSecs(n)}${sleptNote(n)})`; continue; }
    ban(`${n} FAILED in parallel (rc=${rc}) — retrying serially, alone`);
    const lg = tmp(`fg-${n}.log`), imgs = tmp(`fg-${n}.failure-images`), pimgsDir = tmp(`fg-${n}.parallel-fail.images`);
    outTail(lg, 15);
    try { fs.copyFileSync(lg, tmp(`fg-${n}.parallel-fail.log`)); } catch (e) { /* as bash's cp 2>/dev/null */ }
    fs.rmSync(pimgsDir, { recursive: true, force: true });
    let pimgs = '';
    if (nonEmptyDir(imgs)) { fs.renameSync(imgs, pimgsDir); pimgs = `; its failure images at ${pimgsDir}`; }
    await killBrowsers();
    const rc2 = await runLeg(n);
    if (rc2 === 0) {
      run.tally += ` ${n}:PASS-serial-only`; run.warn = true;
      say(`⚠ ${n}: FAILED-parallel/PASSED-serial — possible load-sensitive nondeterminism (see Fizzygum-tests/DETERMINISM.md); parallel log kept at ${tmp(`fg-${n}.parallel-fail.log`)}${pimgs}`);
    } else if (rc2 === 3 && run.infra.has(n)) {
      run.tally += ` ${n}:INFRA-FLAKE`; run.warn = true;
      say(`⚠ ${n}: INFRA shard-drop (exit 3) — zero failed tests, NOT a test/audit failure (plan P6). Re-run the gate if paranoid; log: ${lg}`);
    } else {
      run.tally += ` ${n}:FAIL`; run.ok = false;
      say(`--- ${n} serial retry also FAILED ---`); outTail(lg, 25);
      if (nonEmptyDir(imgs)) say(`  failure images: ${imgs}`);
    }
  }
}
function nonEmptyDir(d) { try { return fs.readdirSync(d).length > 0; } catch (e) { return false; } }
// legs_all_ran <leg…>: a leg the run named with no result fails the run
function legsAllRan(run, names) {
  const ran = new Set(run.res.map(([n]) => n));
  for (const n of names) if (!ran.has(n)) { run.tally += ` ${n}:NEVER-RAN`; run.ok = false; say(`✗ ${n} never ran: no wave started it`); }
}
const minsSecs = (s) => `${Math.floor(s / 60)}m${s % 60}s`;
// a run a signal interrupted stops between its phases: its exit code (its verdict says INTERRUPTED), else 0
const stopped = () => sup.interruptedRc() || 0;

// ---- presuite and gauntlet --------------------------------------------------------------------------------------------
// INNER-LOOP tier: build + the presuite's legs at once (the suite at 8 shards)
async function presuite(args) {
  verdictStart('presuite');
  if (await suiteProfileOrRefuse(args)) { verdictEnd('presuite', 2, 'REFUSED — the profile ships no harness page'); return 2; }
  const p = tableNames('presuite'), inf = tableNames('infra');
  if (p.error || inf.error) { sup.err((p.error || inf.error) + '\n'); verdictEnd('presuite', 2, 'REFUSED — the leg table (buildSystem/legs.js) cannot be run'); return 2; }
  legsPending('presuite', p.names);
  const tAll = seconds();
  if (await runLint()) { verdictEnd('presuite', 1, 'FAILED — lint'); return stopped() || 1; }
  if (await fgBuild(args)) { verdictEnd('presuite', 1, 'FAILED — build'); return stopped() || 1; }
  if (stopped()) return stopped();
  await killBrowsers();
  const run = newRun(inf.names);
  setVar('FG_SUITE_SHARDS', '8');
  ban(`PRESUITE WAVE: ${L.legsIn('presuite').join(' ∥ ')}   — the suite at 8 shards, paint at 5`);
  await runWave(run, p.names);
  if (stopped()) return stopped();
  await collectAndRetry(run);
  if (stopped()) return stopped();
  legsAllRan(run, p.names);
  const total = seconds() - tAll;
  if (run.ok) { ban(`PRESUITE OK —${run.tally} — total ${minsSecs(total)}`); verdictEnd('presuite', 0, `OK —${run.tally} total=${total}s`); return 0; }
  ban(`PRESUITE FAILED —${run.tally} — total ${minsSecs(total)}`); verdictEnd('presuite', 1, `FAILED —${run.tally} total=${total}s`); return 1;
}

async function gauntlet(args) {
  verdictStart('gauntlet');
  if (await suiteProfileOrRefuse(args)) { verdictEnd('gauntlet', 2, 'REFUSED — the profile ships no harness page'); return 2; }
  const lists = ['gauntlet', 'infra', 'A', 'B', 'C', 'D'].map(tableNames);
  const bad = lists.find((x) => x.error);
  if (bad) { sup.err(bad.error + '\n'); verdictEnd('gauntlet', 2, 'REFUSED — the leg table (buildSystem/legs.js) cannot be run'); return 2; }
  const [all, inf, A, B, C, D] = lists.map((x) => x.names);
  legsPending('gauntlet', all);
  if (process.env.FG_GAUNTLET_SERIAL === '1') {
    // the SERIAL escape hatch: the table's legs one after another, in wave order, the suites at 8 shards
    if (await fgBuild(args)) { verdictEnd('gauntlet', 1, 'FAILED — build'); return stopped() || 1; }
    let tally = '', ok = true;
    setVar('FG_SUITE_SHARDS', '8');
    for (const n of all) {
      if (stopped()) return stopped();
      await killBrowsers();
      const rc = await runLeg(n);
      say(`--- ${n} ---`); await legHeadline(n);
      if (rc === 0) tally += ` ${n}:PASS${slept.has(n) ? `(slept ${slept.get(n)}s)` : ''}`;
      else if (rc === 3 && inf.includes(n)) { tally += ` ${n}:INFRA-FLAKE`; say(`⚠ ${n}: INFRA shard-drop (exit 3) — zero failed tests, not a failure (plan P6)`); }
      else { tally += ` ${n}:FAIL`; ok = false; outTail(tmp(`fg-${n}.log`), 15); }
    }
    if (stopped()) return stopped();
    if (ok) { ban(`GAUNTLET OK —${tally}`); verdictEnd('gauntlet', 0, `OK —${tally}`); return 0; }
    ban(`GAUNTLET FAILED —${tally}`); verdictEnd('gauntlet', 1, `FAILED —${tally}`); return 1;
  }
  // the PARALLEL path: lint, build, ONE browser kill, waves A..D, then the serial retries
  const tAll = seconds();
  if (await runLint()) { verdictEnd('gauntlet', 1, 'FAILED — lint'); return stopped() || 1; }
  if (await fgBuild(args)) { verdictEnd('gauntlet', 1, 'FAILED — build'); return stopped() || 1; }
  if (stopped()) return stopped();
  await killBrowsers();
  const run = newRun(inf);
  ban(`WAVE A: ${A.join(' ∥ ')}`);
  await runWave(run, A);
  if (stopped()) return stopped();
  setVar('FG_GATE_SHARDS', '4');
  ban(`WAVE B: ${B.join(' ∥ ')}   (gates at ${vars.FG_GATE_SHARDS} shards)`);
  await runWave(run, B);
  if (stopped()) return stopped();
  setVar('FG_GATE_SHARDS', '6');
  ban(`WAVE C: ${C.join(' ∥ ')}   (gates at ${vars.FG_GATE_SHARDS} shards)`);
  await runWave(run, C);
  if (stopped()) return stopped();
  ban(`WAVE D: ${D.join(' ∥ ')}`);
  await runWave(run, D);
  if (stopped()) return stopped();
  setVar('FG_SUITE_SHARDS', '8'); setVar('FG_GATE_SHARDS', '6');
  await collectAndRetry(run);
  if (stopped()) return stopped();
  legsAllRan(run, all);
  const total = seconds() - tAll;
  if (run.ok) {
    if (run.warn) { ban(`GAUNTLET OK (load-flake warning, see above) —${run.tally} — total ${minsSecs(total)}`); verdictEnd('gauntlet', 0, `OK(warn) —${run.tally} total=${total}s`); }
    else { ban(`GAUNTLET OK —${run.tally} — total ${minsSecs(total)}`); verdictEnd('gauntlet', 0, `OK —${run.tally} total=${total}s`); }
    return 0;
  }
  ban(`GAUNTLET FAILED —${run.tally} — total ${minsSecs(total)}`); verdictEnd('gauntlet', 1, `FAILED —${run.tally} total=${total}s`); return 1;
}

module.exports = { FZ, FT, ROOT, TMP, tmp, L, railsRefusal, setVar, vars, childEnv, out, say, ban, stamp, seconds, forEachLine,
  grepLast, fileHas, tailText, outTail, launch, capture, withLog, killBrowsers, verdictStart, verdictEnd, openVerdicts,
  markRunning, runningFile, readRunning, runningFiles, killStaleRuns, acquireLongOp, releaseAll, tableNames, fgBuild, suiteProfileOrRefuse, fgSuite, runLint, legsPending, runLeg,
  legSecs, legHeadline, newRun, runWave, collectAndRetry, legsAllRan, presuite, gauntlet, tailHead, onPath };

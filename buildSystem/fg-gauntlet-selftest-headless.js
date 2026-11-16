'use strict';
// fg-gauntlet-selftest-headless.js — `fg gauntlet` end to end, through the REAL entry point (Fizzygum/fg) and fg's real
// modules, copied into a temp workspace beside a small leg table whose steps are tiny node scripts, a stand-in build, a
// stand-in profile reader and a stand-in `pkill` first on PATH (so the run never touches a real browser: this self-test
// runs in the gauntlet's own `selftests` leg, beside wave A's suites). fg's logs and verdicts go to the copy's own temp
// directory through its FG_TMP test rail. It holds the worst outcome the port could have — a run that says OK when a
// leg failed — to every path a verdict takes: a green run is OK; a failing leg whose retry fails is FAILED; one whose
// retry passes is OK(warn); an infra leg's exit 3 is INFRA-FLAKE; a leg whose pass line is missing FAILS; a leg past its
// alarm FAILS with its tree killed; a broken table and a failing build refuse or fail before any leg runs; a leg no wave
// ran is impossible by the table (legs-selftest.js holds NEVER-RAN). Then the plan's DRILLS, standing (its §7 steps 6 and 9):
// a SIGTERM mid-wave is INTERRUPTED (143) with no process of the run left; after a SIGKILL `fg status` says STALE and
// `fg killz` kills what the dead run left; a second long operation is REFUSED (its verdict says so); an error thrown in fg
// is INVALID (2); a leg table that cannot even load is REFUSED with its verdict; the build's ceiling fails a hanging build;
// a closed stdout does not end the run. (docs/archive/fg-node-port-plan.md §7 steps 6 and 9.)
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn, spawnSync } = require('child_process');
const t = require('./lib/selftest-verdict').cases('fg-gauntlet');

const FZ_REAL = path.resolve(__dirname, '..');
const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'fg-gauntlet-selftest-'));
const FZ = path.join(temp, 'Fizzygum'), FT = path.join(temp, 'Fizzygum-tests'), TMP = path.join(temp, 'tmp'), BIN = path.join(temp, 'bin');
const write = (p, text, mode) => { fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, text); if (mode) fs.chmodSync(p, mode); };
// fg's own modules; NOT the build-inputs reader `fg status` asks, so every case holds that fg loads without it (a drill
// below stands one in)
for (const f of ['fg', 'buildSystem/fg-commit-point.js', 'buildSystem/fg-verbs.js', 'buildSystem/lib/fg-supervisor.js']) write(path.join(FZ, f), fs.readFileSync(path.join(FZ_REAL, f), 'utf8'));
write(path.join(FZ, 'build_it_please.sh'), '#!/bin/sh\necho "[selftests] OK"\n[ -f "$FG_FAKE_BUILD_FAILS_FILE" ] && exit 1\n[ -f "$FG_FAKE_BUILD_HANGS_FILE" ] && sleep 30\necho "done!!!"\n', 0o755);
// the stand-in profile reader: the calls fg's commit point makes, in-process, answering a dev profile that ships the
// harness page
const PROFILE = path.join(FZ, 'buildSystem/lib/profile.js');
const PROFILE_STAND_IN = "module.exports = { inDirectory: (dir, fn) => fn(), profileNameFromArgv: () => 'dev',\n" +
  "  resolve: (name) => ({ name, shipsHarnessEntry: true }), loadParts: () => ({}), bootFiles: () => {}, finishCommandLine: () => {} };\n";
write(PROFILE, PROFILE_STAND_IN);
write(path.join(BIN, 'pkill'), '#!/bin/sh\nexit 1\n', 0o755);
// a step: prints its name, then does what the file named by its argument says (an exit code, "hang", "nopass")
write(path.join(FT, 'scripts/step.js'), `
const fs = require('fs');
const [name] = process.argv.slice(2);
const plan = fs.existsSync(process.env.FG_FAKE_PLAN_FILE) ? JSON.parse(fs.readFileSync(process.env.FG_FAKE_PLAN_FILE, 'utf8')) : {};
const count = process.env.FG_FAKE_PLAN_FILE + '.' + name;
const n = fs.existsSync(count) ? Number(fs.readFileSync(count, 'utf8')) : 0;
fs.writeFileSync(count, String(n + 1));
const what = [].concat(plan[name] === undefined ? 0 : plan[name]);
const now = what[Math.min(n, what.length - 1)];
console.log(now === 'nopass' ? name + ' ran, no verdict line' : name + ' ran: STEP OK');
if (now === 'hang') {
  const g = require('child_process').spawn(process.execPath, ['-e', 'setInterval(() => {}, 1000)'], { stdio: 'ignore' });
  fs.appendFileSync(process.env.FG_FAKE_PLAN_FILE + '.pids', process.pid + ' ' + g.pid + '\\n');
  setInterval(() => {}, 1000);
}
else process.exit(now === 'nopass' ? 0 : now);
`);
write(path.join(FT, 'scripts/run-all-headless.js'), "console.log('suite ' + process.argv.slice(2).join(' ') + '\\nwall-clock 1s');\n");
const STEP = (name, alarm = 30) => ({ cwd: 'tests', alarm, script: 'scripts/step.js', args: [name] });
const TABLE = [
  { name: 'suite', waves: ['A', 'presuite'], steps: [{ suite: ['--shards={SUITE_SHARDS}'] }], headline: 'wall-clock' },
  { name: 'gate', waves: ['A'], steps: [STEP('gate', 3)], headline: 'STEP', passLine: 'STEP OK' },
  { name: 'audit', waves: ['B'], steps: [STEP('audit')], headline: 'STEP', infraExit: true },
  { name: 'lone', waves: ['C'], steps: [STEP('lone')], headline: 'STEP' },
  { name: 'last', waves: ['D'], steps: [STEP('last')], headline: 'STEP' },
];
const legsCode = fs.readFileSync(path.join(FZ_REAL, 'buildSystem/legs.js'), 'utf8');
const table = (rows) => {
  const a = legsCode.indexOf('\nconst LEGS = [\n'), b = legsCode.indexOf('\n];\n', a);
  write(path.join(FZ, 'buildSystem/legs.js'), legsCode.slice(0, a) + '\nconst LEGS = ' + JSON.stringify(rows) + ';\n' + legsCode.slice(b + 4));
};
table(TABLE);

let runNo = 0;
// one `fg gauntlet` (or another verb) through the real entry point; `plan` says what each step does
function fg(args, plan = {}, extraEnv = {}) {
  fs.rmSync(TMP, { recursive: true, force: true });
  fs.mkdirSync(TMP, { recursive: true });
  const planFile = path.join(temp, `plan-${++runNo}.json`);
  fs.writeFileSync(planFile, JSON.stringify(plan));
  const r = spawnSync(process.execPath, [path.join(FZ, 'fg'), ...args], { encoding: 'utf8', timeout: 120000,
    env: { PATH: BIN + ':' + process.env.PATH, HOME: process.env.HOME, FG_TEST_RAILS: '1', FG_TMP: TMP, FG_FAKE_PLAN_FILE: planFile, ...extraEnv } });
  let verdict = '';
  try { verdict = fs.readFileSync(path.join(TMP, `fg-${args[0]}.verdict`), 'utf8').trim(); } catch (e) { /* none */ }
  return { status: r.status, out: r.stdout + r.stderr, verdict };
}
const log = (leg) => { try { return fs.readFileSync(path.join(TMP, `fg-${leg}.log`), 'utf8'); } catch (e) { return ''; } };
const alive = (pid) => { try { process.kill(pid, 0); return true; } catch (e) { return e.code === 'EPERM'; } };
const pidsOf = (n) => { try { return fs.readFileSync(path.join(temp, `plan-${n}.json.pids`), 'utf8').split(/\s+/).filter(Boolean).map(Number); } catch (e) { return []; } };
const sleep = (ms) => new Promise((res) => setTimeout(res, ms));
const ENV = (planFile, extra = {}) => ({ PATH: BIN + ':' + process.env.PATH, HOME: process.env.HOME, FG_TEST_RAILS: '1', FG_TMP: TMP, FG_FAKE_PLAN_FILE: planFile, ...extra });
// one fg in the background, for the drills: → { child, done, planNo }
function fgStart(args, plan = {}, extra = {}, opts = {}) {
  fs.rmSync(TMP, { recursive: true, force: true });
  fs.mkdirSync(TMP, { recursive: true });
  const planFile = path.join(temp, `plan-${++runNo}.json`);
  fs.writeFileSync(planFile, JSON.stringify(plan));
  const child = spawn(process.execPath, [path.join(FZ, 'fg'), ...args], { env: ENV(planFile, extra), stdio: ['ignore', opts.pipe ? 'pipe' : 'ignore', 'ignore'] });
  const done = new Promise((res) => child.on('exit', (code, signal) => res({ code, signal })));
  return { child, done, planNo: runNo, planFile };
}
async function untilStepRuns(r) { for (let i = 0; i < 200 && pidsOf(r.planNo).length < 2; i++) await sleep(100); await sleep(300); }
const verdictOf = (cmd) => { try { return fs.readFileSync(path.join(TMP, `fg-${cmd}.verdict`), 'utf8').trim(); } catch (e) { return ''; } };
const within = (p, ms) => Promise.race([p, sleep(ms).then(() => 'timeout')]);

try {
  let r = fg(['gauntlet']);
  t.check(r.status === 0 && /^GAUNTLET EXIT=0 OK — suite:PASS\(\d+s\) gate:PASS\(\d+s\) audit:PASS\(\d+s\) lone:PASS\(\d+s\) last:PASS\(\d+s\) total=\d+s/.test(r.verdict),
    'a green gauntlet: exit 0, every leg PASS in wave order', r.verdict + '\n' + r.out.slice(-600));
  t.check(/suite --shards=4 --shards=8/.test(log('suite')) && /fg-leg: gate rc=0 \d+s\n$/.test(log('gate')),
    'a suite leg at the wave\'s 4 shards (fg\'s --shards=8 last); each log ends with its fg-leg stamp', log('suite') + log('gate'));

  r = fg(['gauntlet'], { lone: 1 });
  t.check(r.status === 1 && /^GAUNTLET EXIT=1 FAILED — .* lone:FAIL /.test(r.verdict) && /lone FAILED in parallel \(rc=1\)/.test(r.out),
    'a leg that fails, and fails its serial retry: the gauntlet FAILS (exit 1)', r.verdict);
  r = fg(['gauntlet'], { lone: [1, 0] });
  t.check(r.status === 0 && /^GAUNTLET EXIT=0 OK\(warn\) — .* lone:PASS-serial-only /.test(r.verdict),
    'a leg that fails in its wave and passes alone: OK with the load-flake warning', r.verdict);
  r = fg(['gauntlet'], { audit: 3 });
  t.check(r.status === 0 && /audit:INFRA-FLAKE/.test(r.verdict) && /^GAUNTLET EXIT=0 OK\(warn\)/.test(r.verdict),
    'an infra leg\'s exit 3 twice: INFRA-FLAKE, a warning, never a FAIL', r.verdict);
  r = fg(['gauntlet'], { last: 3 });
  t.check(r.status === 1 && /last:FAIL/.test(r.verdict), 'exit 3 from a leg the table does not mark infra is a FAIL', r.verdict);
  r = fg(['gauntlet'], { gate: 'nopass' });
  t.check(r.status === 1 && /gate:FAIL/.test(r.verdict), 'a leg that exits 0 without its pass line FAILS', r.verdict);
  r = fg(['gauntlet'], { gate: 'hang' });
  const hung = pidsOf(runNo);
  t.check(r.status === 1 && /gate:FAIL/.test(r.verdict) && /timed out after 3 s/.test(log('gate')) && /fg-leg: gate rc=1 /.test(log('gate'))
    && hung.length >= 2 && hung.every((p) => !alive(p)),
    'a leg past its alarm: its tree killed (the step AND its child), the leg FAILS (1: a leg with a pass line), the gauntlet FAILS', r.verdict + log('gate') + hung);
  r = fg(['gauntlet'], { gate: 3 });
  t.check(r.status === 1 && /fg-leg: gate rc=1 /.test(log('gate')), 'a leg with a pass line whose step exits non-zero is 1, as bash made it', log('gate'));

  r = fg(['presuite']);
  t.check(r.status === 0 && /^PRESUITE EXIT=0 OK — suite:PASS\(\d+s\) total=\d+s/.test(r.verdict) && /suite --shards=8 --shards=8/.test(log('suite')),
    'the presuite: its legs, the suite at 8 shards', r.verdict + log('suite'));
  r = fg(['gauntlet'], {}, { FG_GAUNTLET_SERIAL: '1' });
  t.check(r.status === 0 && /^GAUNTLET EXIT=0 OK — suite:PASS gate:PASS audit:PASS lone:PASS last:PASS \(/.test(r.verdict), 'the serial path: every leg, in wave order', r.verdict);

  fs.writeFileSync(path.join(temp, 'build-fails'), '');
  r = fg(['gauntlet'], {}, { FG_FAKE_BUILD_FAILS_FILE: path.join(temp, 'build-fails') });
  t.check(r.status === 1 && /^GAUNTLET EXIT=1 FAILED — build/.test(r.verdict) && !fs.existsSync(path.join(temp, `plan-${runNo}.json.gate`)),
    'a failing build fails the gauntlet before any leg runs', r.verdict);
  table([...TABLE, { ...TABLE[3] }]);
  r = fg(['gauntlet']);
  t.check(r.status === 2 && /^GAUNTLET EXIT=2 REFUSED — the leg table/.test(r.verdict) && /named twice/.test(r.out), 'a table fg cannot run: REFUSED (exit 2) before anything is built', r.verdict + r.out);
  table(TABLE);
  r = fg(['nosuchverb']);
  t.check(r.status === 2, 'an unknown verb exits 2: a mistyped gating command never reads as a pass', String(r.status));
  r = spawnSync(process.execPath, [path.join(FZ, 'fg'), 'help'], { encoding: 'utf8', env: { PATH: BIN + ':' + process.env.PATH, HOME: process.env.HOME, FG_TMP: TMP } });
  t.check(r.status === 2 && /FG_TMP is a test rail, refused outside a test/.test(r.stderr), 'a test rail outside a test (no FG_TEST_RAILS=1) is refused, exit 2', r.status + r.stderr);
} catch (e) { t.check(false, 'the self-test ran to its end', e.stack); }

(async () => {
  try {
    // B1: a SIGTERM mid-wave — INTERRUPTED, 143, no process of the run left
    let r = fgStart(['gauntlet'], { gate: 'hang' });
    await untilStepRuns(r);
    r.child.kill('SIGTERM');
    let end = await within(r.done, 15000);
    await sleep(500);
    t.check(end.code === 143 && /^GAUNTLET EXIT=143 INTERRUPTED by SIGTERM \(/.test(verdictOf('gauntlet')) && pidsOf(r.planNo).every((p) => !alive(p)),
      'a SIGTERM mid-wave: exit 143, the verdict INTERRUPTED, the leg\'s whole tree killed (B1)', JSON.stringify(end) + verdictOf('gauntlet'));

    // B2: a SIGKILL mid-wave — `fg status` says STALE, `fg killz` kills what the dead run left
    r = fgStart(['gauntlet'], { gate: 'hang' });
    await untilStepRuns(r);
    r.child.kill('SIGKILL');
    await r.done;
    const left = pidsOf(r.planNo).filter(alive);
    const st = spawnSync(process.execPath, [path.join(FZ, 'fg'), 'status'], { env: ENV(r.planFile), encoding: 'utf8' });
    t.check(/fg-gauntlet +STALE — fg is gone \(killed or crashed\); not a result/.test(st.stdout), 'after a SIGKILL, fg status says STALE (B2)', st.stdout.slice(-400));
    const kz = spawnSync(process.execPath, [path.join(FZ, 'fg'), 'killz'], { env: ENV(r.planFile), encoding: 'utf8' });
    await sleep(300);
    t.check(left.length >= 2 && pidsOf(r.planNo).every((p) => !alive(p)) && /killed \d+ process\(es\) that a dead fg run left behind: gauntlet \(pid \d+\)/.test(kz.stdout),
      'fg killz kills the programs the dead run left behind', `${left.length} left; ${kz.stdout}`);

    // B6: one long operation at a time — a second is REFUSED, its verdict says so
    r = fgStart(['gauntlet'], { gate: 'hang' });
    await untilStepRuns(r);
    const b = spawnSync(process.execPath, [path.join(FZ, 'fg'), 'build'], { env: ENV(r.planFile), encoding: 'utf8', timeout: 30000 });
    t.check(b.status === 2 && /REFUSED — another fg long operation is running: gauntlet \(pid \d+\)/.test(b.stderr)
      && /^BUILD EXIT=2 REFUSED — another fg long operation was running: gauntlet/.test(verdictOf('build')),
      'a second long operation is REFUSED (exit 2), and its verdict says so (B6)', b.status + b.stderr + verdictOf('build'));
    r.child.kill('SIGTERM');
    await within(r.done, 15000);

    // B3: an error thrown in fg — INVALID, 2 (a planted table whose list throws on the presuite's banner)
    const thrower = path.join(temp, 'throwing-table.js');
    fs.writeFileSync(thrower, `const L = require(${JSON.stringify(path.join(FZ, 'buildSystem/legs.js'))});\nlet n = 0;\n` +
      "module.exports = { ...L, legsIn: (w) => { if (w === 'presuite' && ++n === 2) throw new Error('a planted bug'); return L.legsIn(w); } };\n");
    r = fgStart(['presuite'], {}, { FG_LEGS_TABLE: thrower });
    end = await within(r.done, 30000);
    t.check(end.code === 2 && /^PRESUITE EXIT=2 INVALID — fg internal error: a planted bug/.test(verdictOf('presuite')), 'an error thrown in fg: exit 2, the verdict INVALID (B3)', JSON.stringify(end) + verdictOf('presuite'));

    // B12: a leg table that cannot even load — REFUSED with its verdict; other verbs still work
    const broken = path.join(temp, 'broken-table.js');
    fs.writeFileSync(broken, 'module.exports = { this is not JavaScript\n');
    r = fgStart(['gauntlet'], {}, { FG_LEGS_TABLE: broken });
    end = await within(r.done, 30000);
    const help = spawnSync(process.execPath, [path.join(FZ, 'fg'), 'help'], { env: ENV(r.planFile, { FG_LEGS_TABLE: broken }), encoding: 'utf8' });
    t.check(end.code === 2 && /^GAUNTLET EXIT=2 REFUSED — the leg table/.test(verdictOf('gauntlet')) && help.status === 0,
      'a leg table that cannot load: the gauntlet is REFUSED with its verdict, `fg help` still answers (B12)', JSON.stringify(end) + verdictOf('gauntlet') + help.status);

    // the same for the profile reader fg asks in-process: one that cannot load refuses a suite tier before anything is
    // built (exit 2, its verdict says so), and `fg status` and `fg help` still answer
    fs.writeFileSync(PROFILE, 'module.exports = { this is not JavaScript\n');
    const unread = fg(['presuite']);
    const statusUnread = spawnSync(process.execPath, [path.join(FZ, 'fg'), 'status'], { env: ENV(path.join(temp, 'no-plan.json')), encoding: 'utf8' });
    const helpUnread = spawnSync(process.execPath, [path.join(FZ, 'fg'), 'help'], { env: ENV(path.join(temp, 'no-plan.json')), encoding: 'utf8' });
    fs.writeFileSync(PROFILE, PROFILE_STAND_IN);
    t.check(unread.status === 2 && /^PRESUITE EXIT=2 REFUSED/.test(unread.verdict) && /could not read the build profile — nothing was built/.test(unread.out)
      && /SyntaxError/.test(unread.out) && !/done!!!/.test(unread.out) && statusUnread.status === 0 && /build: MISSING/.test(statusUnread.stdout)
      && helpUnread.status === 0 && /fg status/.test(helpUnread.stdout),
    'a profile reader that cannot load: presuite is REFUSED before the build, `fg status` and `fg help` still answer',
    unread.status + unread.verdict + unread.out + statusUnread.status + statusUnread.stdout.slice(-300) + helpUnread.status);

    // `fg status`'s build line, on a copy that has a tree: with no build-inputs reader it reads STALE (inputs it cannot
    // list), then a stand-in reader answers stale (at most three inputs named) and fresh; the first two words stay
    const BUILT = path.join(temp, 'Fizzygum-builds', 'latest', 'index.html'), INPUTS = path.join(FZ, 'buildSystem/lib/build-inputs.js');
    const buildLine = () => {
      const st = spawnSync(process.execPath, [path.join(FZ, 'fg'), 'status'], { env: ENV(path.join(temp, 'no-plan.json')), encoding: 'utf8' });
      return { status: st.status, text: st.stdout.split('\n').filter((l) => /^  build: |^           \S/.test(l)).join('\n') };
    };
    write(BUILT, '<!doctype html>\n');
    const noReader = buildLine();
    const reader = (staleness) => write(INPUTS, `module.exports = { lastBuildTime: () => ${Date.UTC(2026, 0, 2, 3, 4, 5)}, buildStaleness: () => (${staleness}) };\n`);
    reader("{ stale: true, why: 'W', changed: ['a', 'b'], added: ['c'], removed: ['d'] }");
    const stale = buildLine();
    reader('{ stale: false }');
    const fresh = buildLine();
    fs.rmSync(INPUTS); fs.rmSync(BUILT);
    const at = '\\(the last build started \\d{4}-\\d\\d-\\d\\d \\d\\d:\\d\\d:\\d\\d\\)';
    t.check(noReader.status === 0 && /^  build: STALE — the build's inputs cannot be listed: Cannot find module/.test(noReader.text)
      && stale.status === 0 && new RegExp(`^  build: STALE ${at} — W, e\\.g\\.:\\n {11}a \\(changed\\)\\n {11}b \\(changed\\)\\n {11}c \\(added\\)$`).test(stale.text)
      && fresh.status === 0 && new RegExp(`^  build: FRESH ${at}$`).test(fresh.text),
    "fg status's build line: inputs it cannot list read STALE; a stale answer names at most three inputs; a fresh one says when the build started",
    [noReader, stale, fresh].map((x) => x.status + ' ' + x.text).join('\n'));

    // B11: the build's ceiling
    fs.writeFileSync(path.join(temp, 'build-hangs'), '');
    r = fgStart(['build'], {}, { FG_BUILD_ALARM_SECS: '1', FG_FAKE_BUILD_HANGS_FILE: path.join(temp, 'build-hangs') });
    end = await within(r.done, 30000);
    t.check(end.code === 1 && /^BUILD EXIT=1 FAILED/.test(verdictOf('build')) && /timed out after 1 s/.test(log('build')),
      'a hanging build is killed past its ceiling: FAILED, its log says it timed out (B11)', JSON.stringify(end) + verdictOf('build'));

    // B4: a closed stdout does not end the run
    r = fgStart(['gauntlet'], {}, {}, { pipe: true });
    await new Promise((res) => r.child.stdout.once('data', res));
    r.child.stdout.destroy();
    end = await within(r.done, 60000);
    t.check(end.code === 0 && /^GAUNTLET EXIT=0 OK/.test(verdictOf('gauntlet')), 'a closed stdout (EPIPE) does not end the run: it finishes, OK (B4)', JSON.stringify(end) + verdictOf('gauntlet'));
  } catch (e) { t.check(false, 'the drills ran to their end', e.stack); }
  finally { fs.rmSync(temp, { recursive: true, force: true }); }
  t.done();
})();

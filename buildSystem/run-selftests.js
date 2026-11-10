#!/usr/bin/env node
'use strict';
// run-selftests.js — runs every SELF-TEST in both repos, found by NAME, never listed.
//
// A self-test is a checker's proof that it can fail. One that nothing runs proves nothing: the checker can be wrong on
// every build in between and nobody learns it (docs/archive/unrun-checks-plan.md). So a self-test is a FILE,
// named for its subject, and this runs them all:
//   <subject>-selftest.js           pure Node, no build, no browser — the BUILD runs these (build_it_please.sh), and
//                                   so does `npm run selftest` in Fizzygum-tests (--repo=tests);
//   <subject>-selftest-headless.js  boots the built page — the gauntlet's `selftests` leg runs these (--headless).
// The naming table is lib/what-runs.js's CONVENTIONS, which check-hand-lists.js reads too, so what this runs and what
// a sanction may lean on cannot disagree.
//
// EACH ONE PASSES only when it exits 0 AND its last stdout line is the shared verdict (lib/selftest-verdict.js) with
// at least one case. Otherwise:
//   SELFTEST_FAILED      it exited non-zero, or its verdict says FAIL
//   SELFTEST_NO_VERDICT  it exited 0 without the verdict line — it may have stopped early, or judged nothing
//   SELFTEST_VACUOUS     its verdict counts zero cases
// AND A SELF-TEST CANNOT HIDE OUTSIDE THE CONVENTION, two ways:
//   SELFTEST_OUTSIDE_CONVENTION  a script's CODE offers a self-test switch — a `--self-test` / `--selftest` argument
//                                (a string literal, `=value` included, or a lib/cli.js flag reader asking for one), a
//                                `…SELFTEST` environment variable read or set, a shell command passing such a flag.
//                                Prose may mention one (comments, a printing command); code may not offer one.
//   SELFTEST_UNDISCOVERED        a file in either repo NAMED like a self-test (self-test / selftest / self_test in its
//                                name) that no tier runs: misspelt (`x.selftest.js`, `x-self-test.js`), the wrong
//                                extension, or outside the directories the conventions scan. node_modules, dot-dirs and
//                                the tests repo's tests/ (test content) are not scripts.
// This file and lib/selftest-verdict.js are the machinery, exempt from both: they name the spellings to refuse them.
// AND EVERY GATE BITES (the node tier of a full run — the build's): every script the build or an `fg` leg LAUNCHES
// (lib/what-runs.js's run set: ANY launch edge makes it a program — but never an instrument a gate injects, nor a
// self-test, which is a proof judged by the rules above) is a gate unless its header says why not (`// not-a-gate: <reason>`, `#` in a shell or Python file), and a gate
//   GATE_WITHOUT_REGISTRY  names its rules through lib/gate-rules.js — JS: `require(…gate-rules…).forGate(__filename)`
//                          in its code; shell: a `gate_rules_init` call (the twin in Fizzygum-tests/scripts/lib/
//                          audited-suite-with-infra-retry.sh) — so its exits are held to its rules;
//   GATE_WITHOUT_PROOF     is LAUNCHED by a self-test that requires and calls a proof helper (lib/planted-src.js proveGate, or the
//                          tests repo's lib/gate-bite-proof.js proveLeg), which plants each of those rules.
// A new gate therefore arrives with its proof or fails the build.
//
// Files run a POOL at a time, LONGEST FIRST (by the time each took on the previous run: see longestFirst), and their
// reports print in discovery order whatever order they start or finish in. Every gate's
// bite-proof is one more file (a static gate's runs the real gate on a planted copy of src/, a suite gate's boots its
// real gate on one test), so one at a time would grow the build's first gate and the gauntlet's selftests leg with
// every proof added. The node tier runs NODE_POOL at once (each is CPU-bound and writes only its own temp files); the
// headless tier HEADLESS_POOL, each file's own runs sequential, its children told to keep sibling files' browsers
// (FIZZYGUM_KEEP_STALE_BROWSERS=1: a runner otherwise culls every headless browser it did not launch).
//
// Usage: node buildSystem/run-selftests.js [--headless] [--repo=fizzygum|tests] [--umbrella=DIR]
// --umbrella=DIR reads another workspace (DIR/Fizzygum, DIR/Fizzygum-tests, DIR/fg) in place of this one: a miniature
// workspace carrying planted self-tests, the bite-proof's input (run-selftests-selftest.js).
// Exit: 0 every self-test passed · 1 one failed (or one hides outside the convention) · 2 operational (none found).
// The tests repo's half runs when ../Fizzygum-tests is present, and says when it is not.

const fs = require('fs');
const path = require('path');
const { spawn, execFileSync } = require('child_process');
const { DEFAULT_LAYOUT, discover, scriptFiles, skippedEntry, shellCommands, runSet, jsLaunches } = require('./lib/what-runs');
const { maskJs } = require('./lib/js-mask');
const { VERDICT_RE } = require('./lib/selftest-verdict');

const rules = require('./lib/gate-rules').forGate(__filename);
const { dirArg } = require('./lib/cli-args');
// judge()'s tokens: each a rule of this gate
rules.declare(['SELFTEST_FAILED', 'SELFTEST_NO_VERDICT', 'SELFTEST_VACUOUS']);

const SELF = path.resolve(__filename);
const MACHINERY = new Set([SELF, require.resolve('./lib/selftest-verdict')]);
// the workspace read: this one, or the one --umbrella= names (main sets it before anything reads it)
let LAYOUT = DEFAULT_LAYOUT;
const umbrella = () => path.dirname(LAYOUT.fizzygum);

const repoOf = (f) => (f.startsWith(LAYOUT.tests + path.sep) ? 'tests' : 'fizzygum');
const rootOf = (repo) => (repo === 'tests' ? LAYOUT.tests : LAYOUT.fizzygum);
const rel = (f) => path.relative(umbrella(), f);
const testsPresent = () => fs.existsSync(path.join(LAYOUT.tests, 'scripts'));
// 8 node files at once (2026-11-07, every-gate-bites: 48 node self-tests, most of them a gate run on a planted copy,
// took 5.7 s at 4 and 4.3 s at 8 on a 16-core machine at load 5; the build's budget for this step is 6 s idle)
const NODE_POOL = 8;
// 6 headless files at once (2026-11-07, every-gate-bites: every leg's bite-proof made the tier 22 files and ~750
// lane-seconds; at 3 they took 261 s on an idle machine, over the leg's budget — wave A's longest leg, ~211 s in-wave)
const HEADLESS_POOL = 6;

// The pid and every descendant of it (ps), deepest first: a headless self-test runs gates that run runners, and a
// timeout that killed only the file would leave them running — and writing — after the verdict.
function processTree(pid) {
  let rows = [];
  try { rows = execFileSync('ps', ['-A', '-o', 'pid=,ppid='], { encoding: 'utf8' }).trim().split('\n').map((l) => l.trim().split(/\s+/).map(Number)); } catch (e) { /* no ps: the file alone */ }
  const tree = [pid];
  for (let i = 0; i < tree.length; i++) for (const [p, pp] of rows) if (pp === tree[i]) tree.push(p);
  return tree.reverse();
}

// One self-test file, run to completion: { status, error?, stdout, stderr }, the shape judge() reads. A run past its
// time limit is killed with everything it started, and reads as an error, never as a pass; so does a file that could
// not be spawned at all.
function runFile(f, { timeoutSecs, env }) {
  return new Promise((resolve) => {
    const child = spawn(process.execPath, [f], { cwd: rootOf(repoOf(f)), env });
    let stdout = '', stderr = '', error, settled = false;
    const finish = (status) => { if (settled) return; settled = true; clearTimeout(timer); resolve({ status, error, stdout, stderr }); };
    child.stdout.setEncoding('utf8'); child.stderr.setEncoding('utf8');
    child.stdout.on('data', (d) => { stdout += d; });
    child.stderr.on('data', (d) => { stderr += d; });
    const timer = setTimeout(() => {
      error = { code: 'ETIMEDOUT' };
      for (const p of processTree(child.pid)) { try { process.kill(p, 'SIGKILL'); } catch (e) { /* already gone */ } }
    }, timeoutSecs * 1000);
    child.on('error', (e) => { error = e; if (child.pid === undefined) finish(null); });
    child.on('close', (status) => finish(status));
  });
}

// Runs every file, at most `width` at a time, and hands each result to `report` in the files' own order.
// The order files START in, as indices into `files`: longest first, by the seconds each took on the previous run
// (`durations`, keyed by path), so the longest proof cannot start last and alone set the tier's length — the pool is a
// longest-processing-time-first schedule. A file with no recorded time starts first; ties keep discovery order.
function longestFirst(files, durations) {
  const secs = (f) => (Object.prototype.hasOwnProperty.call(durations, f) ? +durations[f] : Infinity);
  return files.map((f, i) => i).sort((a, b) => (secs(files[b]) - secs(files[a])) || (a - b));
}
// Where those times are kept between runs: a scheduling hint, read and written best-effort — it never decides a
// verdict, and without it the files start in discovery order.
const DURATIONS_FILE = path.join(require('os').tmpdir(), 'fizzygum-selftest-durations.json');
const readDurations = () => { try { return JSON.parse(fs.readFileSync(DURATIONS_FILE, 'utf8')); } catch (e) { return {}; } };

async function runAll(files, width, opts, report, order = files.map((f, i) => i)) {
  const results = new Array(files.length);
  let next = 0, printed = 0;
  const flush = () => { while (printed < files.length && results[printed]) { report(files[printed], results[printed]); printed++; } };
  const worker = async () => {
    while (next < files.length) {
      const i = order[next++], t = Date.now();
      const r = await runFile(files[i], opts);
      r.secs = ((Date.now() - t) / 1000).toFixed(2);
      results[i] = r;
      flush();
    }
  };
  await Promise.all(Array.from({ length: Math.min(width, files.length) }, worker));
}

// ---- a self-test switch in code, outside the convention ---------------------------------------------------------
const FLAG_VALUE = /^--self-?test(=.*)?$/i;
const ENV_NAME = /\w*SELF_?TEST\w*/i;
// [{ line, what }] for a script's TEXT, by its extension (.js, .sh, .py; anything else offers nothing)
function offeredFlags(text, ext) {
  const out = [];
  const lineAt = (i) => text.slice(0, i).split('\n').length;
  if (ext === '.js') {
    const { mask } = maskJs(text);
    for (let i = 0; i < text.length;) {
      if (mask[i] !== 'str') { i++; continue; }
      let j = i; while (j < text.length && mask[j] === 'str') j++;
      const literal = text.slice(i, j);   // its quotes are part of the run
      if (FLAG_VALUE.test(literal.replace(/^['"\x60]|['"\x60]$/g, ''))) out.push({ line: lineAt(i), what: literal });
      i = j;
    }
    const code = [
      /process\.env\.\w*SELF_?TEST\w*/gi,                                          // process.env.X_SELFTEST
      /process\.env\[\s*['"\x60]\w*SELF_?TEST/gi,                                    // process.env['X_SELFTEST']
      /\{[^}]*SELF_?TEST\w*[^}]*\}\s*=\s*process\.env/gi,                           // const { X_SELFTEST } = process.env
      /\b(?:flag|flagValue|argValue|makeFlag\([^()]*\))\s*\(\s*(?:\w+\s*,\s*)?['"\x60]-*self-?test['"\x60]/gi,   // lib/cli.js readers
    ];
    for (const re of code) for (const m of text.matchAll(re)) if (mask[m.index] === 'code') out.push({ line: lineAt(m.index), what: m[0] });
  } else if (ext === '.sh') {
    for (const words of shellCommands(text)) {
      const program = words.find((w) => !/^[A-Za-z_]\w*=/.test(w.text));
      if (program && !program.headQuoted && ['echo', 'printf', 'ban', ':'].includes(program.text)) continue;
      for (const w of words) {
        if (FLAG_VALUE.test(w.text) || new RegExp('^' + ENV_NAME.source + '=', 'i').test(w.text) || new RegExp('\\$\\{?' + ENV_NAME.source, 'i').test(w.text)) {
          out.push({ line: lineAt(text.indexOf(w.text)) || 1, what: w.text });
        }
      }
    }
  } else if (ext === '.py') {
    text.split('\n').forEach((raw, k) => {
      const m = raw.replace(/#.*$/, '').match(/(['"])--self-?test(=[^'"]*)?\1/i);
      if (m) out.push({ line: k + 1, what: m[0] });
    });
  }
  return out;
}

// Files NAMED like a self-test that are neither discovered nor the machinery: [abs path]. Pure: the caller walks.
function undiscovered(files, discovered) {
  return files.filter((f) => /self[-_ ]?test/i.test(path.basename(f)) && !discovered.has(f) && !MACHINERY.has(f));
}

// every file of a repo that could be a script, skipping what is never the tooling (what-runs.js skippedEntry: dot
// entries, node_modules, __pycache__) and the tests repo's tests/
function repoFiles(root, skipDirs) {
  const out = [];
  const walk = (dir) => {
    if (!fs.existsSync(dir)) return;
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      if (skippedEntry(e.name)) continue;
      const p = path.join(dir, e.name);
      if (e.isDirectory()) { if (!skipDirs.includes(p)) walk(p); } else out.push(p);
    }
  };
  walk(root);
  return out;
}

// ---- every launched gate has a registry and a proof ------------------------------------------------------------
// → { noRegistry: [file], noProof: [file], gates } over a workspace's run set, or undefined for a fixture workspace
// with no build script (only an --umbrella miniature has none).
// `not-a-gate: <reason>` counts only in the file's HEADER — its leading block of comment, shebang, 'use strict' and
// blank lines: a line further down is a comment about something else, never the file's own statement of what it is.
const NOT_A_GATE_RE = /^[ \t]*(?:\/\/|#)[ \t]*not-a-gate:[ \t]*(\S.*)$/m;
const HEADER_LINE_RE = /^[ \t]*(?:$|#|\/\/|\/\*|\*|['"]use strict['"];?[ \t]*$)/;
const headerOf = (text) => {
  const lines = text.split('\n'), out = [];
  for (const l of lines) { if (!HEADER_LINE_RE.test(l)) break; out.push(l); }
  return out.join('\n');
};
// a require( … ) call, one level of nested parentheses deep (`require(path.join(LIB, 'gate-rules'))`), and what follows it
const REQUIRE_CALL_RE = /require\((?:[^()]|\([^()]*\))*\)(\s*\.forGate\(\s*__filename\s*\))?/g;
const inCode = (text, test) => {
  const { mask } = maskJs(text);
  return [...text.matchAll(REQUIRE_CALL_RE)].some((m) => mask[m.index] === 'code' && test(m));
};
const usesRegistry = (text) => inCode(text, (m) => /gate-rules['"]/.test(m[0]) && !!m[1]);
// a proof REQUIRES a proof helper and CALLS it, both in code: a helper required and never called proves nothing
const PROOF_CALL_RE = /\b(?:proveGate|proveLeg)\s*\(/g;
const usesProofHelper = (text) => inCode(text, (m) => /(?:planted-src|gate-bite-proof)['"]/.test(m[0])) &&
  (() => { const { mask } = maskJs(text); return [...text.matchAll(PROOF_CALL_RE)].some((m) => mask[m.index] === 'code'); })();
function gateCensus(layout, isUmbrella) {
  if (isUmbrella && !fs.existsSync(path.join(layout.fizzygum, 'build_it_please.sh'))) return undefined;
  const rs = runSet(layout);
  const instruments = new Set(discover('prelude', layout));
  const files = scriptFiles(layout);
  const resolveToken = (tok) => files.filter((f) => f.endsWith('/' + tok) || path.basename(f) === tok);
  // what each self-test that uses a proof helper launches
  const proved = new Set();
  const proofs = [...discover('selftest', layout), ...discover('selftestHeadless', layout)];
  for (const p of proofs) {
    const text = fs.readFileSync(p, 'utf8');
    if (!usesProofHelper(text)) continue;
    for (const l of jsLaunches(p, text)) if (!l.required) for (const f of resolveToken(l.token)) proved.add(f);
  }
  // not gates: an instrument a gate injects (`*-prelude.js`), and a self-test — a proof, judged by this runner's own
  // SELFTEST_* rules, however else it is reached (a gate that builds its own self-test's path to skip it reads as one)
  const notGates = new Set([...instruments, ...proofs]);
  const gates = [...rs.files].filter((f) => rs.how.get(f) === 'launched' && !notGates.has(f)).sort();
  const noRegistry = [], noProof = [], exempt = [];
  for (const f of gates) {
    const text = fs.readFileSync(f, 'utf8');
    if (NOT_A_GATE_RE.test(headerOf(text))) { exempt.push(f); continue; }
    const registry = f.endsWith('.js') ? usesRegistry(text)
      : f.endsWith('.sh') ? shellCommands(text).some((w) => w[0] && w[0].text === 'gate_rules_init' && !w[0].headQuoted) : false;
    if (!registry) noRegistry.push(f);
    if (!proved.has(f)) noProof.push(f);
  }
  return { noRegistry, noProof, gates: gates.length - exempt.length, exempt: exempt.length };
}

// ---- the verdict on one run: a failure token, or undefined for a pass ---------------------------------------------
// r: { status, error?, stdout }. Passes only on exit 0 AND a last stdout line that is the shared verdict, PASS, with
// at least one case.
function judge(r) {
  const lines = (r.stdout || '').split('\n').map((l) => l.trimEnd()).filter(Boolean);
  const m = VERDICT_RE.exec(lines[lines.length - 1] || '');
  const n = m ? +m[4] : 0;
  if (r.error || r.status !== 0 || (m && m[2] === 'FAIL')) return { token: 'SELFTEST_FAILED', cases: n };
  if (!m) return { token: 'SELFTEST_NO_VERDICT', cases: 0 };
  if (n === 0) return { token: 'SELFTEST_VACUOUS', cases: 0 };
  return { token: undefined, cases: n };
}

// ---- run ---------------------------------------------------------------------------------------------------------
async function main(argv) {
  const KNOWN = /^--(headless|repo=(fizzygum|tests)|umbrella=.*)$/;
  for (const a of argv) if (!KNOWN.test(a)) { console.error(`[selftests] ERROR — unknown argument '${a}' (--headless, --repo=fizzygum|tests, --umbrella=DIR)`); process.exit(2); }
  const givenUmbrella = dirArg(argv, '--umbrella=', undefined, 'selftests');
  if (givenUmbrella) LAYOUT = { fizzygum: path.join(givenUmbrella, 'Fizzygum'), tests: path.join(givenUmbrella, 'Fizzygum-tests'), fg: path.join(givenUmbrella, 'fg') };
  const HEADLESS = argv.includes('--headless');
  const REPO = (argv.find((a) => a.startsWith('--repo=')) || '').slice('--repo='.length) || undefined;
  const inScope = (f) => !REPO || repoOf(f) === REPO;
  const kind = HEADLESS ? 'selftestHeadless' : 'selftest';
  const tests = discover(kind, LAYOUT).filter(inScope);
  const tier = HEADLESS ? 'headless tier (-selftest-headless.js)' : 'node tier (-selftest.js)';
  if (!tests.length) { console.error(`[selftests] ERROR — no ${tier} self-test found${REPO ? ` in ${REPO}` : ''}: a runner that finds nothing certifies nothing`); process.exit(2); }
  const counts = ['fizzygum', 'tests'].filter((r) => !REPO || r === REPO).map((r) => `${r === 'tests' ? 'Fizzygum-tests' : 'Fizzygum'} ${tests.filter((f) => repoOf(f) === r).length}`);
  console.log(`[selftests] ${tier}: ${tests.length} self-test(s) — ${counts.join(', ')}${!testsPresent() && REPO !== 'fizzygum' ? ' (Fizzygum-tests absent: its half SKIPPED)' : ''}`);

  const failures = [];
  let cases = 0;
  const t0 = Date.now();
  const env = HEADLESS ? { ...process.env, FIZZYGUM_KEEP_STALE_BROWSERS: '1' } : process.env;
  // the headless limit sits under the gauntlet leg's own alarm (600 s), so this runner always reports before it is killed
  const durations = readDurations(), took = {};
  await runAll(tests, HEADLESS ? HEADLESS_POOL : NODE_POOL, { timeoutSecs: HEADLESS ? 480 : 120, env }, (f, r) => {
    took[f] = +r.secs;
    const secs = r.secs;
    const { token, cases: n } = judge(r);
    if (token) {
      failures.push(f);
      console.error(rules.fired(token, `  ${token}  ${rel(f)}  (exit ${r.error ? r.error.code || r.error.message : r.status}, ${secs}s)`));
      const out = `${r.stdout || ''}${r.stderr || ''}`.split('\n').filter(Boolean);
      for (const l of out.slice(-40)) console.error(`      ${l}`);
    } else {
      cases += n;
      console.log(`  PASS  ${rel(f)} — ${n} case${n === 1 ? '' : 's'} (${secs}s)`);
    }
  }, longestFirst(tests, durations));
  // the next run's schedule (a miniature workspace's files are temporary: their times are not kept)
  if (!givenUmbrella) {
    const kept = Object.fromEntries(Object.entries(durations).filter(([f]) => fs.existsSync(f)));
    try { fs.writeFileSync(DURATIONS_FILE, JSON.stringify({ ...kept, ...took }, null, 1) + '\n'); } catch (e) { /* a hint */ }
  }

  const hiding = [];
  for (const f of scriptFiles(LAYOUT).filter(inScope)) {
    if (MACHINERY.has(path.resolve(f))) continue;
    for (const o of offeredFlags(fs.readFileSync(f, 'utf8'), path.extname(f))) hiding.push(`${rel(f)}:${o.line}  ${o.what}`);
  }
  for (const h of hiding) console.error(rules.fired('SELFTEST_OUTSIDE_CONVENTION', `  SELFTEST_OUTSIDE_CONVENTION  ${h}`));
  const allSelfTests = new Set([...discover('selftest', LAYOUT), ...discover('selftestHeadless', LAYOUT)]);
  const stray = undiscovered([
    ...(!REPO || REPO === 'fizzygum' ? repoFiles(LAYOUT.fizzygum, []) : []),
    ...(!REPO || REPO === 'tests' ? repoFiles(LAYOUT.tests, [path.join(LAYOUT.tests, 'tests')]) : []),
  ], allSelfTests);
  for (const f of stray) console.error(rules.fired('SELFTEST_UNDISCOVERED', `  SELFTEST_UNDISCOVERED  ${rel(f)}`));
  // the gate census — the build's run (node tier, both repos) holds every launched gate to a registry and a proof
  const census = !HEADLESS && !REPO ? gateCensus(LAYOUT, !!givenUmbrella) : undefined;
  const unproved = census ? census.noRegistry.length + census.noProof.length : 0;
  if (census) {
    for (const f of census.noRegistry) console.error(rules.fired('GATE_WITHOUT_REGISTRY', `  GATE_WITHOUT_REGISTRY  ${rel(f)}`));
    for (const f of census.noProof) console.error(rules.fired('GATE_WITHOUT_PROOF', `  GATE_WITHOUT_PROOF  ${rel(f)}`));
    if (unproved) {
      console.error('      Every script the build or an fg leg launches is a gate: it names its rules (lib/gate-rules.js; a shell');
      console.error('      gate gate_rules_init) and a self-test plants each one (proveGate / proveLeg, launching it by');
      console.error('      path.join(__dirname, …)) — or its header says why it is not one: `// not-a-gate: <reason>`.');
    }
  }
  if (hiding.length || stray.length) {
    console.error('      A self-test is a <subject>-selftest.js (or -selftest-headless.js) file among the tooling\'s own files');
    console.error('      (lib/what-runs.js scriptFiles), found and run by name; a switch that runs one, or a file named like one');
    console.error('      that no tier finds, is a self-test nothing runs.');
  }

  const secs = ((Date.now() - t0) / 1000).toFixed(1);
  const gatesNote = census ? `; gates: ${census.gates} launched, each with a registry and a proof (${census.exempt} not a gate, stated)` : '';
  if (failures.length || hiding.length || stray.length || unproved) {
    console.error(`[selftests] FAIL — ${failures.length} of ${tests.length} self-test(s) failed, ${hiding.length} outside the convention, ${stray.length} undiscovered` +
      (census ? `, ${census.noRegistry.length} gate(s) without a registry, ${census.noProof.length} without a proof` : '') + ` (${secs}s)`);
    process.exitCode = 1;
  } else {
    console.log(`[selftests] OK — ${tests.length} self-test(s), ${cases} cases, ${secs}s${gatesNote}`);
  }
}

module.exports = { judge, offeredFlags, undiscovered, processTree, gateCensus, longestFirst };

if (require.main === module) {
  // a run that ends without reaching its verdict (the event loop drained with a file still owed) is no pass
  let concluded = false;
  process.on('exit', () => { if (!concluded && !process.exitCode) { console.error('[selftests] ERROR — the run ended before its verdict'); process.exitCode = 2; } });
  main(process.argv.slice(2)).then(() => { concluded = true; }, (e) => { concluded = true; console.error(`[selftests] ERROR — ${e.stack || e}`); process.exitCode = 2; });
}

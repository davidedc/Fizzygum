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
//
// Usage: node buildSystem/run-selftests.js [--headless] [--repo=fizzygum|tests]
// Exit: 0 every self-test passed · 1 one failed (or one hides outside the convention) · 2 operational (none found).
// The tests repo's half runs when ../Fizzygum-tests is present, and says when it is not.

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const { DEFAULT_LAYOUT, discover, scriptFiles, shellCommands } = require('./lib/what-runs');
const { maskJs } = require('./lib/js-mask');
const { VERDICT_RE } = require('./lib/selftest-verdict');

const SELF = path.resolve(__filename);
const MACHINERY = new Set([SELF, require.resolve('./lib/selftest-verdict')]);
const UMBRELLA = path.dirname(DEFAULT_LAYOUT.fizzygum);

const repoOf = (f) => (f.startsWith(DEFAULT_LAYOUT.tests + path.sep) ? 'tests' : 'fizzygum');
const rootOf = (repo) => (repo === 'tests' ? DEFAULT_LAYOUT.tests : DEFAULT_LAYOUT.fizzygum);
const rel = (f) => path.relative(UMBRELLA, f);
const testsPresent = fs.existsSync(path.join(DEFAULT_LAYOUT.tests, 'scripts'));

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

// every file of a repo that could be a script: node_modules, dot-dirs and the tests repo's tests/ are skipped
function repoFiles(root, skipDirs) {
  const out = [];
  const walk = (dir) => {
    if (!fs.existsSync(dir)) return;
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      if (e.name.startsWith('.') || e.name === 'node_modules') continue;
      const p = path.join(dir, e.name);
      if (e.isDirectory()) { if (!skipDirs.includes(p)) walk(p); } else out.push(p);
    }
  };
  walk(root);
  return out;
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
function main(argv) {
  const KNOWN = /^--(headless|repo=(fizzygum|tests))$/;
  for (const a of argv) if (!KNOWN.test(a)) { console.error(`[selftests] ERROR — unknown argument '${a}' (--headless, --repo=fizzygum|tests)`); process.exit(2); }
  const HEADLESS = argv.includes('--headless');
  const REPO = (argv.find((a) => a.startsWith('--repo=')) || '').slice('--repo='.length) || undefined;
  const inScope = (f) => !REPO || repoOf(f) === REPO;
  const kind = HEADLESS ? 'selftestHeadless' : 'selftest';
  const tests = discover(kind).filter(inScope);
  const tier = HEADLESS ? 'headless tier (-selftest-headless.js)' : 'node tier (-selftest.js)';
  if (!tests.length) { console.error(`[selftests] ERROR — no ${tier} self-test found${REPO ? ` in ${REPO}` : ''}: a runner that finds nothing certifies nothing`); process.exit(2); }
  const counts = ['fizzygum', 'tests'].filter((r) => !REPO || r === REPO).map((r) => `${r === 'tests' ? 'Fizzygum-tests' : 'Fizzygum'} ${tests.filter((f) => repoOf(f) === r).length}`);
  console.log(`[selftests] ${tier}: ${tests.length} self-test(s) — ${counts.join(', ')}${!testsPresent && REPO !== 'fizzygum' ? ' (Fizzygum-tests absent: its half SKIPPED)' : ''}`);

  const failures = [];
  let cases = 0;
  const t0 = Date.now();
  for (const f of tests) {
    const t = Date.now();
    const r = spawnSync(process.execPath, [f], { cwd: rootOf(repoOf(f)), encoding: 'utf8', maxBuffer: 256 * 1024 * 1024, timeout: (HEADLESS ? 600 : 120) * 1000 });
    const secs = ((Date.now() - t) / 1000).toFixed(2);
    const { token, cases: n } = judge(r);
    if (token) {
      failures.push(f);
      console.error(`  ${token}  ${rel(f)}  (exit ${r.error ? r.error.code || r.error.message : r.status}, ${secs}s)`);
      const out = `${r.stdout || ''}${r.stderr || ''}`.split('\n').filter(Boolean);
      for (const l of out.slice(-40)) console.error(`      ${l}`);
    } else {
      cases += n;
      console.log(`  PASS  ${rel(f)} — ${n} case${n === 1 ? '' : 's'} (${secs}s)`);
    }
  }

  const hiding = [];
  for (const f of scriptFiles().filter(inScope)) {
    if (MACHINERY.has(path.resolve(f))) continue;
    for (const o of offeredFlags(fs.readFileSync(f, 'utf8'), path.extname(f))) hiding.push(`${rel(f)}:${o.line}  ${o.what}`);
  }
  for (const h of hiding) console.error(`  SELFTEST_OUTSIDE_CONVENTION  ${h}`);
  const allSelfTests = new Set([...discover('selftest'), ...discover('selftestHeadless')]);
  const stray = undiscovered([
    ...(!REPO || REPO === 'fizzygum' ? repoFiles(DEFAULT_LAYOUT.fizzygum, []) : []),
    ...(!REPO || REPO === 'tests' ? repoFiles(DEFAULT_LAYOUT.tests, [path.join(DEFAULT_LAYOUT.tests, 'tests')]) : []),
  ], allSelfTests);
  for (const f of stray) console.error(`  SELFTEST_UNDISCOVERED  ${rel(f)}`);
  if (hiding.length || stray.length) {
    console.error('      A self-test is a <subject>-selftest.js (or -selftest-headless.js) file under buildSystem/ or');
    console.error('      Fizzygum-tests/scripts/, found and run by name; a switch that runs one, or a file named like one');
    console.error('      that no tier finds, is a self-test nothing runs.');
  }

  const secs = ((Date.now() - t0) / 1000).toFixed(1);
  if (failures.length || hiding.length || stray.length) {
    console.error(`[selftests] FAIL — ${failures.length} of ${tests.length} self-test(s) failed, ${hiding.length} outside the convention, ${stray.length} undiscovered (${secs}s)`);
    process.exitCode = 1;
  } else {
    console.log(`[selftests] OK — ${tests.length} self-test(s), ${cases} cases, ${secs}s`);
  }
}

module.exports = { judge, offeredFlags, undiscovered };

if (require.main === module) main(process.argv.slice(2));

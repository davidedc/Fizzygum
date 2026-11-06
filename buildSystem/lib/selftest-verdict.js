'use strict';
// selftest-verdict.js — the ONE verdict line every self-test ends with, in both repos:
//   [<name>] SELFTEST PASS — <n> cases            exit code 0
//   [<name>] SELFTEST FAIL — <f> of <n> cases     exit code 1
// buildSystem/run-selftests.js reads it (VERDICT_RE). A self-test that never reaches its verdict, or reaches it
// having judged nothing, proves nothing, so the runner fails the first as SELFTEST_NO_VERDICT and the second as
// SELFTEST_VACUOUS — which is why a self-test counts every case it judges rather than printing "OK".
//
//   const t = require('…/selftest-verdict').cases('my-thing');
//   t.check(got === want, 'what this case shows', `got ${got}`);   // prints "  ok  …" or "  FAIL …"
//   t.done();                                                       // the verdict line + process.exitCode
// or, for a self-test that keeps its own counters: verdict('my-thing', passed, failed).
//
// The exit code is SET, never forced with process.exit(): a runner reads this output through a pipe, and a bare
// process.exit() drops whatever stdout still holds (Fizzygum-tests/scripts/lib/safe-exit.js).

const VERDICT_RE = /^\[([\w.-]+)\] SELFTEST (PASS|FAIL) — (?:(\d+) of )?(\d+) cases?$/;

function verdict(name, passed, failed) {
  const n = passed + failed;
  console.log(failed
    ? `[${name}] SELFTEST FAIL — ${failed} of ${n} case${n === 1 ? '' : 's'}`
    : `[${name}] SELFTEST PASS — ${n} case${n === 1 ? '' : 's'}`);
  process.exitCode = failed ? 1 : (process.exitCode || 0);
  return failed ? 1 : 0;
}

function cases(name) {
  let passed = 0, failed = 0;
  return {
    check(good, label, detail) {
      if (good) passed++; else failed++;
      // one stream, so a runner reading the output sees each FAIL where it happened, above the verdict
      console.log(`  ${good ? 'ok  ' : 'FAIL'} ${label}${detail !== undefined && !good ? ` — ${detail}` : ''}`);
      return !!good;
    },
    get passed() { return passed; },
    get failed() { return failed; },
    done() { return verdict(name, passed, failed); },
  };
}

module.exports = { VERDICT_RE, verdict, cases };

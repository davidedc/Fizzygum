'use strict';
// census-public-private-calls-selftest.js — the census's call-shape decision (classifyOccurrence) on fixture lines:
// what reads as a CALL, a plain REFERENCE, or neither (an assignment, a property chain). The rule it reads references
// by and the tests-repo reader it reads R4's external half through own their cases in lib/. Run by
// buildSystem/run-selftests.js on every build.

const { classifyOccurrence } = require('./census-public-private-calls');
const t = require('./lib/selftest-verdict').cases('census-public-private-calls');

const CASES = [
  ['@foo()', 'foo', 'call'], ['@foo(a, b)', 'foo', 'call'],
  ['@foo a', 'foo', 'call'], ['@foo @bar', 'foo', 'call'], ["@foo 'x'", 'foo', 'call'],
  ['@foo if x', 'foo', 'ref'], ['@foo and @bar', 'foo', 'ref'], ['x = @foo', 'foo', 'ref'],
  ['@foo = 3', 'foo', 'skip'], ['@foo ?= 3', 'foo', 'skip'], ['@foo.bar()', 'foo', 'skip'],
  ['return unless @foo', 'foo', 'ref'],
];
for (const [line, name, expect] of CASES) {
  const got = classifyOccurrence(line, line.indexOf('@' + name) + 1 + name.length);
  t.check(got === expect, `${JSON.stringify(line)} -> ${got} (expected ${expect})`);
}

t.done();

'use strict';
// prove-rules-selftest.js — lib/prove-rules.js, the judge every bite-proof shares, held to what it promises. Each case
// hands proveRules a SCRIPTED gate (exec returns canned results, no process) and a recording case set, then asks what
// the judge concluded: a correct proof passes, and a proof whose control fails, whose planted run fires a neighbour,
// misses a rule's own line, or leaves a rule unplanted FAILS; an INVALID run (exit: 2) is judged as INVALID and never
// as coverage. planted-src-selftest.js proves the same judge end to end through proveGate on a real fake gate. Run by
// buildSystem/run-selftests.js on every build.

const { proveRules } = require('./prove-rules');
const t = require('./selftest-verdict').cases('prove-rules');

// a recording case set: what the judge checked, and which checks failed
function recorder() {
  const failed = [];
  let n = 0;
  return { check: (ok, what) => { n++; if (!ok) failed.push(what); return !!ok; }, failed, count: () => n };
}
const rulesOf = (fired, of) => ({ fired: new Set(fired), of: new Set(of), unplantable: new Set() });
const PASS = { status: 0, out: '[g] OK', rules: undefined, why: 'pass', missed: [] };
const fail = (fired, out, of = ['A', 'B']) => ({ status: 1, out, rules: rulesOf(fired, of), why: 'fail', missed: [] });
const invalid = (out) => ({ status: 2, out, rules: undefined, why: 'invalid', missed: [] });

// a scripted gate: the control (no label) gets `control`, each run gets results[label]
function judge(runs, results, control = PASS) {
  const r = recorder();
  proveRules(r, { pass: /\[g\] OK/, runs }, (run) => (run.label ? results[run.label] : control));
  return r;
}

{
  const r = judge([{ label: 'a', expect: { A: /^line A$/m } }, { label: 'b', expect: { B: /^line B$/m } }],
    { a: fail(['A'], 'line A'), b: fail(['B'], 'line B') });
  t.check(!r.failed.length && r.count() > 0, 'a proof planting every rule, each by its own line, passes', r.failed.join('; '));
}
{
  const r = judge([{ label: 'a', expect: { A: /^line A$/m, B: /^line B$/m } }], { a: fail(['A', 'B'], 'line A\nline B') },
    { status: 1, out: 'boom', rules: rulesOf(['A'], ['A', 'B']), why: 'control failed', missed: [] });
  t.check(r.failed.some((w) => /control/.test(w)), 'a control that fails is a failed proof', r.failed.join('; '));
}
{
  const r = judge([{ label: 'a', expect: { A: /^line A$/m } }, { label: 'b', expect: { B: /^line B$/m } }],
    { a: fail(['A', 'B'], 'line A\nline B'), b: fail(['B'], 'line B') });
  t.check(r.failed.some((w) => /a: fires only the rules it plants/.test(w)), 'a plant that also fires a neighbour is a failed proof', r.failed.join('; '));
}
{
  const r = judge([{ label: 'a', expect: { A: /^line A naming the plant$/m, B: /^line B$/m } }], { a: fail(['A', 'B'], 'line A\nline B') });
  t.check(r.failed.some((w) => /bites A/.test(w)), "a rule that fired without its own violation line is a failed proof", r.failed.join('; '));
}
{
  const r = judge([{ label: 'a', expect: { A: /^line A$/m } }], { a: fail(['A'], 'line A') });
  t.check(r.failed.some((w) => /every rule the gate can fire is planted \(1 of 2\)/.test(w)), 'a rule no run planted is a failed proof', r.failed.join('; '));
}
{
  const r = judge([{ label: 'a', expect: { A: /^line A$/m, B: /^line B$/m } },
                   { label: 'blind', exit: 2, lines: [/^INVALID — a bucket nothing observed$/m] }],
    { a: fail(['A', 'B'], 'line A\nline B'), blind: invalid('INVALID — a bucket nothing observed') });
  t.check(!r.failed.length, 'an INVALID run (exit: 2) read as INVALID, beside full coverage, passes', r.failed.join('; '));
}
{
  const r = judge([{ label: 'a', expect: { A: /^line A$/m, B: /^line B$/m } }, { label: 'blind', exit: 2 }],
    { a: fail(['A', 'B'], 'line A\nline B'), blind: fail(['A'], 'line A') });
  t.check(r.failed.some((w) => /blind: the gate reads it INVALID/.test(w)), 'an INVALID plant the gate FAILS on (exit 1, a rule) is a failed proof', r.failed.join('; '));
}
{
  const r = judge([{ label: 'blind', exit: 2 }], { blind: invalid('INVALID') });
  t.check(r.failed.some((w) => /no RULES line read/.test(w) || /planted/.test(w)),
    'INVALID runs alone plant no rule: coverage is unproven, never vacuously complete', r.failed.join('; '));
}
{
  let sized;
  const r = recorder();
  proveRules(r, { pass: /\[g\] OK/, runs: (c) => { sized = c.out; return [{ label: 'a', expect: { A: /x/ } }]; } },
    (run) => (run.label ? fail(['A'], 'x', ['A']) : { ...PASS, out: '[g] OK — 7 counted' }));
  t.check(sized === '[g] OK — 7 counted' && !r.failed.length, "runs may be computed from the control's own output", r.failed.join('; '));
}

t.done();

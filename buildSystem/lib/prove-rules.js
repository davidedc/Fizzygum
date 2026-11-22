'use strict';
// prove-rules.js — the JUDGE every bite-proof shares, whatever runs its gate: a static gate on a planted copy of its
// input tree (lib/planted-src.js's proveGate) or a browser rig with a plant injected into its pages
// (Fizzygum-tests/scripts/lib/gate-bite-proof.js's proveLeg). The caller owns HOW one run happens; this owns what the
// runs together must show, so the two kinds of proof cannot drift into two different ideas of "it bites".
//
//   proveRules(t, spec, exec)        t: a selftest-verdict case set
//     exec(run) → { status, out, rules, advised, why, missed }
//                 ONE gate run carrying `run`'s plants (the control is a run too); `rules` is the gate's parsed RULES
//                 line (lib/gate-rules.js parseRulesLine), `advised` the ADVICE the run printed, counted (a Map from
//                 each rule id to the times its header printed, a class's shared text printed other than once among
//                 them: lib/gate-advice.js parseAdvice; absent reads as none), `missed` the plants that did not apply
//                 (an in-copy edit that matched nothing), `why` what a failed case needs to be read
//     spec.pass          the control's pass line
//     spec.controlLabel  how the control's case names it
//     spec.control       { absent: [re], lines: [re], …plants } — the unplanted input plus every sanctioned form
//     spec.runs          [{ label, expect: { RULE_ID: /its own violation line/ }, advised: [RULE_ID], absent, lines,
//                        exit, …plants }], or a function of the control's result (a ratchet's plant sized by the count
//                        it printed); `advised` is the rules whose advice the run prints — exactly those, none when absent
//
// What it holds:
//   - the CONTROL exits 0 with its pass line and fires no rule; its absent/lines hold;
//   - each PLANTED run exits 1 naming its rules; every expected rule fired AND its own line matches; it fires no rule
//     it did not plant (a plant that trips a neighbour is not isolated); its absent/lines hold;
//   - a run planting a MEASUREMENT failure (`exit: 2` — an INVALID verdict: an unobserved bucket, a dose not taken)
//     exits 2 with its lines and fires no rule: an INVALID is the absence of a verdict, never a rule, so it never
//     counts toward coverage;
//   - each run, the control included, prints the ADVICE of exactly the rules its `advised` names, each header once and
//     each class's shared text once (lib/gate-advice.js): a rule its gate advises on prints, when it fires, what its
//     number holds back and when a raise is the answer, however many lines it fired on, and no other rule prints any.
//     Judged wherever a run prints advice or a run of the spec names `advised`, so a proof whose gate prints no advice
//     and names none is held to nothing more;
//   - over all planted runs, the rules fired are EVERY rule the gate can fire (its `of`, the unplantable ones its
//     header states excluded): a gate that grows a rule fails its proof until the proof plants it.
// Returns { control, runs } — each exec result — for a proof's own `after` checks.

const ruleNames = (ids) => (ids.size ? [...ids].join(' ') : 'no rule');
// what a run printed, read for a failed case: each entry once, or with the times it printed (`timer ×2`)
const printedOf = (got) => (got.size ? [...got].map(([id, n]) => (n === 1 ? id : `${id} ×${n}`)).join(' ') : 'none');

// `r` printed the advice of exactly the rules `run.advised` names, each once
function checkAdvice(t, r, run, label, judged) {
  const got = r.advised || new Map();
  const want = new Set(run.advised || []);
  if (!judged && !got.size && !want.size) return;
  t.check(got.size === want.size && [...want].every((id) => got.get(id) === 1),
    `${label} prints ${want.size ? `the advice of exactly ${ruleNames(want)}, each once` : 'the advice of no rule'}`,
    `it printed the advice ${printedOf(got)} — ${r.why}`);
}

function proveRules(t, spec, exec) {
  const control = spec.control || {};
  const c = exec(control);
  t.check(!(c.missed || []).length && c.status === 0 && spec.pass.test(c.out) && !c.rules,
    spec.controlLabel || 'the control passes',
    (c.missed || []).length ? `edit did not apply: ${c.missed.join('; ')}` : c.why);
  for (const re of control.absent || []) t.check(!re.test(c.out), `the control prints nothing matching ${re}`, c.why);
  for (const re of control.lines || []) t.check(re.test(c.out), `the control prints ${re}`, c.why);

  const firedAll = new Set();
  let of;
  const results = { control: c, runs: [] };
  const runs = typeof spec.runs === 'function' ? spec.runs(c) : spec.runs;
  // a proof that names advice anywhere judges it everywhere: the control and every run say which advice they print
  const judged = control.advised !== undefined || runs.some((run) => run.advised !== undefined);
  checkAdvice(t, c, control, 'the control', judged);
  for (const run of runs) {
    const r = exec(run);
    results.runs.push(r);
    const label = run.label || 'the planted run';
    if ((r.missed || []).length) t.check(false, `${label}: every plant applies`, r.missed.join('; '));
    if (run.exit === 2) {
      t.check(r.status === 2 && !r.rules, `${label}: the gate reads it INVALID (exit 2), firing no rule`, r.why);
    } else {
      t.check(r.status === 1 && !!r.rules, `${label}: the gate fails, naming its rules`, r.why);
    }
    const fired = r.rules ? r.rules.fired : new Set();
    // an INVALID run's rules never count toward coverage (it fails above if it fired any)
    if (r.rules && run.exit !== 2) { of = of || r.rules.of; for (const id of fired) firedAll.add(id); }
    for (const [id, re] of Object.entries(run.expect || {})) {
      t.check(fired.has(id) && re.test(r.out), `bites ${id}`,
        `${fired.has(id) ? 'fired' : 'NOT fired'}; line ${re} ${re.test(r.out) ? 'found' : 'NOT found'} — ${r.why}`);
    }
    const unexpected = [...fired].filter((id) => !(id in (run.expect || {})));
    t.check(!unexpected.length, `${label}: fires only the rules it plants`, `also fired: ${unexpected.join(' ')}`);
    for (const re of run.absent || []) t.check(!re.test(r.out), `${label}: prints nothing matching ${re}`, r.why);
    for (const re of run.lines || []) t.check(re.test(r.out), `${label}: prints ${re}`, r.why);
    checkAdvice(t, r, run, `${label}:`, judged);
  }
  const missing = of ? [...of].filter((id) => !firedAll.has(id)) : ['(no RULES line read)'];
  t.check(!missing.length, `every rule the gate can fire is planted (${firedAll.size} of ${of ? of.size : '?'})`,
    `never planted: ${missing.join(' ')}`);
  return results;
}

module.exports = { proveRules };

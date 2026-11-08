'use strict';
// check-call-separation-selftest.js — check-call-separation.js proved able to BITE, by running the REAL gate (its census
// over the src copy and the tests repo's references) on a planted copy of src/ (lib/planted-src.js). [S]: a private
// method self-calling a public SETTLING command fails, and one self-calling a public EFFECTFUL command fails. [U]: a
// public command referenced only by @-self calls fails; public queries referenced only by @-self calls fail once they
// take the query count over its baseline (the plant is sized from the count the control prints); an allowlist entry
// that gained a real outside reference fails as stale. A self-call is seen whatever comes before it on its line or
// as its argument: one after a regex holding `#`, and a paren-less one given a string. The caller marked
// `# public-call-sanctioned:` passes. The census's
// call-shape decisions are census-public-private-calls-selftest.js; this is the verdict over them. Run by
// buildSystem/run-selftests.js on every build.

const path = require('path');
const { proveGate } = require('./lib/planted-src');
const { readAllowlist } = require('./lib/allowlist-file');

const allowlisted = [...readAllowlist(path.join(__dirname, 'public-api-allowlist.txt')).keys()][0];
const cls = (name, ...body) => [`class ${name} extends Widget`, ...body, ''].join('\n');

proveGate({
  name: 'check-call-separation',
  gate: path.join(__dirname, 'check-call-separation.js'),
  pass: /^\[call-separation\] OK — \[S\] 0\/0 settling \+ 0\/0 effectful/m,
  control: { plants: { 'BiteProofSanctionedCallWdgt.coffee': cls('BiteProofSanctionedCallWdgt', '  _bpSanctioned: ->', '    # public-call-sanctioned: the bite-proof fixture', '    @destroy()') } },
  runs: (control) => {
    const m = /\+ (\d+)\/(\d+) query self-only public methods/.exec(control.out) || [0, 0, 0];
    const k = Math.max(1, Number(m[2]) - Number(m[1]) + 1);   // queries enough to exceed the baseline
    return [{
      label: 'private calls to public commands; self-only public methods; a stale allowlist entry',
      plants: {
        'BiteProofCallSeparationWdgt.coffee': cls('BiteProofCallSeparationWdgt',
          '  _bpPlantedPrivate: ->', '    @destroy()',
          '  bpEffectfulCmd: ->', '    @bpEffectX = 1',
          '  _bpEffectfulCaller: ->', '    @bpEffectfulCmd()',
          '  _bpAfterRegexCaller: ->', '    r = /#x/; @bpEffectfulCmd()',
          '  _bpStringArgCaller: ->', '    @bpEffectfulCmd "a label", 1',
          '  bpSelfOnlyCmd: ->', '    @bpSelfOnlyY = 1',
          '  bpSelfOnlyUser: ->', '    @bpSelfOnlyCmd()',
          ...Array.from({ length: k }, (_, i) => `  bpSelfOnlyQuery${i}: -> ${i}`),
          '  bpQueryUser: ->', `    ${Array.from({ length: k }, (_, i) => `@bpSelfOnlyQuery${i}()`).join(' + ')}`),
        'BiteProofOutsideCallerWdgt.coffee': cls('BiteProofOutsideCallerWdgt', '  bpUse: (w) ->', '    w.bpEffectfulCmd()', `    w.${allowlisted}()`),
      },
      expect: {
        S_SETTLING_SELF_CALL: /^      BiteProofCallSeparationWdgt\._bpPlantedPrivate -> @destroy  /m,
        S_EFFECTFUL_SELF_CALL: /^      BiteProofCallSeparationWdgt\._bpEffectfulCaller -> @bpEffectfulCmd  /m,
        U_EFFECTFUL_SELF_ONLY: /^  \[U\] EFFECTFUL self-only public methods: \d+ EXCEEDS the baseline/m,
        U_QUERY_SELF_ONLY: /^  \[U\] QUERY self-only public methods: \d+ EXCEEDS the baseline/m,
        U_STALE_ALLOWLIST_ENTRY: new RegExp(`^      STALE_ALLOWLIST_ENTRY ${allowlisted} — no longer a self-only public method`, 'm'),
      },
      lines: [/candidates include: .*bpSelfOnlyCmd/,
        /^      BiteProofCallSeparationWdgt\._bpAfterRegexCaller -> @bpEffectfulCmd  /m,
        /^      BiteProofCallSeparationWdgt\._bpStringArgCaller -> @bpEffectfulCmd  /m],
      absent: [/BiteProofSanctionedCallWdgt/],
    }];
  },
});

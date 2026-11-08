'use strict';
// check-thin-wraps-selftest.js — check-thin-wraps.js proved able to BITE, by running the REAL gate on a planted copy of
// src/ (lib/planted-src.js): a public method owning a _<name>NoSettle twin whose body is more than the canonical wrap
// fails, named; a # thin-wrap-exempt: marker above a method with no twin fails as stale. The accepted shapes ride
// the control and are COUNTED, so each is seen to be accepted rather than skipped: the canonical wrap behind a guard
// and a private twin pair add two canonical wrappers, a marked non-canonical twin owner adds one exemption, a
// twinless _xNoSettle adds nothing, and a marker's words written inside a heredoc are text, not a marker. Run by buildSystem/run-selftests.js on every build.

const path = require('path');
const { spawnSync } = require('child_process');
const { proveGate, FIZZYGUM } = require('./lib/planted-src');

const GATE = path.join(__dirname, 'check-thin-wraps.js');
const real = /\[thin-wraps\] (\d+) canonical wrapper\(s\) \+ (\d+) marked-exempt checked\./.exec(
  spawnSync(process.execPath, [GATE], { cwd: FIZZYGUM, encoding: 'utf8' }).stdout) || [0, -99, -99];
const lines = (...l) => [...l, ''].join('\n');

proveGate({
  name: 'check-thin-wraps',
  gate: GATE,
  pass: /^\[thin-wraps\] OK -- every public\/NoSettle pair is the canonical wrap or marked exempt\.$/m,
  control: {
    plants: {
      'BiteProofAcceptedWrapsWdgt.coffee': lines('class BiteProofAcceptedWrapsWdgt extends Widget',
        '  bpGuarded: (a) ->', '    return if a is @bpValue', '    @_settleLayoutsAfter => @_bpGuardedNoSettle a',
        '  _bpGuardedNoSettle: (a) ->', '    @bpValue = a',
        '  _bpPrivate: ->', '    @_settleLayoutsAfter => @_bpPrivateNoSettle()',
        '  _bpPrivateNoSettle: ->', '    @bpValue = 2',
        '  # thin-wrap-exempt: the bite-proof fixture of check-thin-wraps-selftest.js',
        '  bpMarked: (a) ->', '    @bpExtra = a', '    @_settleLayoutsAfter => @_bpMarkedNoSettle a',
        '  _bpMarkedNoSettle: (a) ->', '    @bpValue = a',
        '  _bpLoneNoSettle: ->', '    @bpValue = 3'),
      'BiteProofHeredocTextWdgt.coffee': lines('class BiteProofHeredocTextWdgt extends Widget',
        '  bpSource: """', '  # thin-wrap-exempt: words inside a heredoc, no marker', '  """'),
    },
    lines: [new RegExp(`^\\[thin-wraps\\] ${Number(real[1]) + 2} canonical wrapper\\(s\\) \\+ ${Number(real[2]) + 1} marked-exempt checked\\.$`, 'm')],
  },
  runs: [{
    label: 'a fat wrap and a marker excusing nothing',
    plants: {
      'BiteProofThinWrapWdgt.coffee': lines('class BiteProofThinWrapWdgt extends Widget',
        '  bpThinWrap: (a) ->', '    @bpExtra = a', '    @_settleLayoutsAfter => @_bpThinWrapNoSettle a',
        '  _bpThinWrapNoSettle: (a) ->', '    @bpValue = a',
        '  # thin-wrap-exempt: excuses nothing — no twin below',
        '  bpNoTwin: ->', '    @bpValue = 4'),
    },
    expect: {
      NOT_CANONICAL: /^  BiteProofThinWrapWdgt\.bpThinWrap  \(BiteProofThinWrapWdgt\.coffee:2\)$/m,
      STALE_EXEMPT_MARKER: /^  STALE_ALLOWLIST_ENTRY BiteProofThinWrapWdgt\.coffee:7$/m,
    },
  }],
});

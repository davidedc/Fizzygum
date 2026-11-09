'use strict';
// check-scheduled-checks-selftest.js — check-scheduled-checks.js proved able to BITE, by running the REAL gate on a
// planted copy of src/ and of the tests repo's harness (lib/planted-src.js): a marker dated in the past fails as
// OVERDUE, in src and in a harness file (named harness/<path>) alike, and one whose date cannot parse fails as
// UNPARSEABLE_DATE, each named by file and line; a marker dated far ahead passes, and so does a past
// date written inside a heredoc (its text, not a comment). (Dates are ISO and
// far from today: the gate reads the clock.) Run by buildSystem/run-selftests.js on every build.

const path = require('path');
const { proveGate } = require('./lib/planted-src');

proveGate({
  name: 'check-scheduled-checks',
  gate: path.join(__dirname, 'check-scheduled-checks.js'),
  testsRepo: true,
  pass: /^\[scheduled-checks\] OK/m,
  control: { plants: {
    'BiteProofNotYetDueCheck.coffee': 'class BiteProofNotYetDueCheck\n  # CHECK AFTER 2999-01-01T00:00:00Z\n  a: -> 1\n',
    'BiteProofHeredocCheck.coffee': 'class BiteProofHeredocCheck\n  a: """\n  # CHECK AFTER 2000-01-01T00:00:00Z\n  """\n',
  } },
  runs: [{
    label: 'an overdue marker and an unparseable one',
    plants: {
      'BiteProofOverdueCheck.coffee': 'class BiteProofOverdueCheck\n  # CHECK AFTER 2000-01-01T00:00:00Z\n  a: -> 1\n',
      'BiteProofUnparseableCheck.coffee': 'class BiteProofUnparseableCheck\n  # CHECK AFTER not-a-date\n  a: -> 1\n',
    },
    expect: {
      OVERDUE: /^  BiteProofOverdueCheck\.coffee:2  \(due: 2000-01-01T00:00:00Z\)$/m,
      UNPARSEABLE_DATE: /^  BiteProofUnparseableCheck\.coffee:2  \(date: "not-a-date"\)$/m,
    },
    absent: [/BiteProofNotYetDueCheck|BiteProofHeredocCheck/],
  }, {
    label: 'a harness file',
    plants: { 'harness/BiteProofHarnessOverdueCheck.coffee': 'class BiteProofHarnessOverdueCheck\n  # CHECK AFTER 2000-01-01T00:00:00Z\n  a: -> 1\n' },
    expect: { OVERDUE: /^  harness\/BiteProofHarnessOverdueCheck\.coffee:2  \(due: 2000-01-01T00:00:00Z\)$/m },
  }],
});

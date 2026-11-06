'use strict';
// cli-args.js — a gate refuses an argument it does not know (exit 2), so a mistyped flag, or one a script no longer
// has, is never read as a run that checked something. The case it exists for: a gate's self-test is a FILE now
// (`<gate>-selftest.js`, run on every build by run-selftests.js), so an old `--self-test` invocation copied from an
// archived plan must not run the gate instead and exit 0, which reads as a passing self-test.
//
//   rejectUnknownArgs(argv, ['--census', '--min='], 'check-hand-lists')
// An entry ending in `=` takes its value in the same argument; any other entry matches the argument exactly. Arguments
// not starting with `--` (paths, a value after a flag) are the caller's business.

const path = require('path');

function rejectUnknownArgs(argv, known, name) {
  for (const a of argv) {
    if (!a.startsWith('--')) continue;
    if (known.some((k) => (k.endsWith('=') ? a.startsWith(k) : a === k))) continue;
    console.error(`[${name}] ERROR — unknown argument '${a}' (known: ${known.join(' ') || 'none'})`);
    if (/self-?test/i.test(a)) {
      console.error(`  its self-test is ${path.join('buildSystem', name + '-selftest.js')}, run on every build by buildSystem/run-selftests.js`);
    }
    process.exit(2);
  }
}

module.exports = { rejectUnknownArgs };

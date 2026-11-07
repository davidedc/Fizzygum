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

// A RAIL: a flag naming the tree a gate reads in place of its default — a copy carrying a plant (a bite-proof's input).
// The rail is the ONE way to point a gate elsewhere (never an environment variable: an export would leak into every
// later run). A rail given twice, empty, or naming no directory is refused (exit 2): `--src=` resolved as-is would be
// the current directory, and a gate would then check the whole repo, or nothing, and pass.
//   const SRC = dirArg(ARGV, '--src=', path.resolve(__dirname, '../src'), 'check-x');
function dirArg(argv, flag, fallback, name) {
  refuseBare(argv, flag, name);
  const given = argv.filter((a) => a.startsWith(flag));
  if (!given.length) return fallback;
  const refuse = (why) => { console.error(`[${name}] ERROR — ${flag}… ${why}`); process.exit(2); };
  if (given.length > 1) refuse('is given more than once');
  const value = given[0].slice(flag.length);
  if (!value) refuse('is empty: it names the directory to read');
  const dir = path.resolve(value);
  let st;
  try { st = require('fs').statSync(dir); } catch (e) { refuse(`names no such directory: ${dir}`); }
  if (!st.isDirectory()) refuse(`names a file, not a directory: ${dir}`);
  return dir;
}

// A rail written with a space (`--src DIR`) is refused (exit 2): its value is read only after the `=`, so the path would
// be dropped and the gate would read its default tree, unplanted.
function refuseBare(argv, flag, name) {
  const bare = flag.replace(/=$/, '');
  if (bare !== flag && argv.includes(bare)) {
    console.error(`[${name}] ERROR — ${bare} takes its value after "=" (${flag}…): a space-separated value is not read`);
    process.exit(2);
  }
}

// The same rail for a FILE the gate reads in place of its default (a planted parts.json): refused when given twice,
// empty, or naming no file.
function fileArg(argv, flag, fallback, name) {
  refuseBare(argv, flag, name);
  const given = argv.filter((a) => a.startsWith(flag));
  if (!given.length) return fallback;
  const refuse = (why) => { console.error(`[${name}] ERROR — ${flag}… ${why}`); process.exit(2); };
  if (given.length > 1) refuse('is given more than once');
  const value = given[0].slice(flag.length);
  if (!value) refuse('is empty: it names the file to read');
  const file = path.resolve(value);
  let st;
  try { st = require('fs').statSync(file); } catch (e) { refuse(`names no such file: ${file}`); }
  if (!st.isFile()) refuse(`names a directory, not a file: ${file}`);
  return file;
}

// A gate that takes no positional argument refuses one (exit 2): a path written where a rail belongs would otherwise be
// ignored, and the gate would check its default tree.
function rejectPositionalArgs(argv, name, hint = '') {
  const stray = argv.find((a) => !a.startsWith('--'));
  if (stray === undefined) return;
  console.error(`[${name}] ERROR — unexpected argument '${stray}'${hint ? ` (${hint})` : ''}`);
  process.exit(2);
}

module.exports = { rejectUnknownArgs, dirArg, fileArg, rejectPositionalArgs };

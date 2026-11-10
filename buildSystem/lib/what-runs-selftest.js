'use strict';
// what-runs-selftest.js — lib/what-runs.js on a miniature workspace written to a temp dir: each way a file can be
// NAMED without being run (a comment, an echo, a help message, a Python docstring) must stay out of the run set, and
// each way one is LAUNCHED (a shell command, a pipeline stage, require(), path.join) must come in — with and without
// the umbrella's `fg`, and through the discovering runners.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { runSet, discover, shellInvocations, scriptFiles } = require('./what-runs');
const { spawnSync } = require('child_process');
const t = require('./selftest-verdict').cases('what-runs');

const root = fs.mkdtempSync(path.join(os.tmpdir(), 'what-runs-selftest-'));
const layout = { fizzygum: path.join(root, 'Fizzygum'), tests: path.join(root, 'Fizzygum-tests'), fg: path.join(root, 'fg') };
const write = (rel, text) => { const p = path.join(root, rel); fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, text); };

write('Fizzygum/build_it_please.sh', [
  '# node ./buildSystem/commented.js',
  'echo "now run ./buildSystem/echoed.js by hand"',
  '[ -d x ] && echo "hint: buildSystem/hinted.js"',
  'node ./buildSystem/gate.js || exit 1',
  'python3 buildSystem/tool.py',
  'node ./buildSystem/run-selftests.js',
  'echo $missing | xargs -I{} bash ../Fizzygum-tests/scripts/piped.sh {}',
  // named, never launched: a test, an echo after a keyword, a bare assignment, a file operation, a heredoc body, a
  // quoted echo spanning lines
  'if [ -f buildSystem/tested.js ]; then echo "hint: buildSystem/then-echoed.js"; fi',
  'GATE=buildSystem/assigned-only.js',
  'echo run it by hand with node buildSystem/echo-unquoted.js',   // an interpreter WORD inside a printing command
  'rm -f buildSystem/removed.js',
  'cat <<EOF',
  'node buildSystem/heredoc.js',
  'EOF',
  'echo "first line',
  '  node buildSystem/multiline-echoed.js"',
  // an assignment heading a command that runs an interpreter launches nothing: no runner takes a script that way
  'ENV_RAIL=buildSystem/env-assigned.js node buildSystem/gate.js',
  // launched: a path built on a substitution, a default in a flag's value, a launch inside a substitution, a script
  // run directly
  'node "$(dirname "$0")/buildSystem/dirname-launched.js"',
  'node buildSystem/gate.js \\',
  '  --prelude="${3:-$PWD/buildSystem/defaulted.js}"',
  'eval "$(node buildSystem/substituted.js "$x")"',
  './buildSystem/direct.sh --flag',
].join('\n'));
write('Fizzygum/buildSystem/gate.js', [
  "const lib = require('./lib/used');",
  "const both = require('./lib/both');",   // a module here, and a program a leg launches (leg.sh)
  "console.error('stale? run buildSystem/messaged.js');",
  "throw new Error('see ' + 'launched-by-message.js');",
  "spawnSync('node', [path.join(__dirname, 'launched.js')]);",
].join('\n'));
for (const f of ['lib/used.js', 'lib/both.js', 'launched.js', 'messaged.js', 'commented.js', 'echoed.js', 'hinted.js', 'run-selftests.js',
                 'beta-selftest-headless.js', 'launched-by-message.js', 'tested.js', 'then-echoed.js', 'assigned-only.js',
                 'removed.js', 'heredoc.js', 'multiline-echoed.js', 'dirname-launched.js', 'defaulted.js', 'substituted.js',
                 'direct.sh', 'cli-tool.js', 'fg-built.js', 'echo-unquoted.js', 'env-assigned.js']) write(`Fizzygum/buildSystem/${f}`, '');
// a self-test exercises its subject on fixtures: a command-line tool only its self-test loads does not RUN
write('Fizzygum/buildSystem/alpha-selftest.js', "const tool = require('./cli-tool');\n");
write('Fizzygum/buildSystem/tool.py', '"""Run Fizzygum-tests/scripts/orphan.js afterwards."""\n');
write('Fizzygum-tests/scripts/piped.sh', '');
write('Fizzygum-tests/scripts/orphan.js', '');
write('Fizzygum-tests/scripts/leg.sh', 'node scripts/runner.js --audit-prelude="$PWD/scripts/p/x-prelude.js"\nnode "$FZ/buildSystem/lib/both.js"\n');
write('Fizzygum-tests/scripts/runner.js', '');
write('Fizzygum-tests/scripts/suite-runner.js', '');
write('Fizzygum-tests/scripts/p/x-prelude.js', '');
write('Fizzygum-tests/scripts/q/y-prelude.js', '');
write('Fizzygum-tests/scripts/preludes-install-selftest-headless.js', '');
write('fg', [
  'fg_build(){', '  ( cd "$FZ" && ./build_it_please.sh "$@" && node buildSystem/fg-built.js )', '}',   // first in the file
  'fg_suite(){ ( cd "$FT" && node scripts/suite-runner.js "$@" ); }   # a one-liner: its body ends on its line',
  'run_lint(){', '  echo "lint names scripts/orphan.js and runs nothing"', '}',
  'run_leg(){', '  case "$1" in',
  '    x) bash "$FT/scripts/leg.sh" ;;',
  '    selftests) ( cd "$FZ" && node buildSystem/run-selftests.js --headless ) ;;',
  '  esac', '}',
  'fg_unrelated(){', '  node scripts/orphan.js', '}',
].join('\n'));

const rel = (s) => [...s].map((f) => path.relative(root, f).replace(/^Fizzygum(-tests)?\//, '')).sort();
const withFg = runSet(layout);
const runs = new Set(rel(withFg.files));
const RUN = ['build_it_please.sh', 'buildSystem/gate.js', 'buildSystem/lib/used.js', 'buildSystem/launched.js', 'buildSystem/tool.py',
             'buildSystem/run-selftests.js', 'buildSystem/alpha-selftest.js', 'scripts/piped.sh',
             'scripts/leg.sh', 'scripts/runner.js', 'scripts/p/x-prelude.js',
             'buildSystem/beta-selftest-headless.js', 'scripts/preludes-install-selftest-headless.js', 'scripts/q/y-prelude.js',
             'buildSystem/dirname-launched.js', 'buildSystem/defaulted.js', 'buildSystem/substituted.js', 'buildSystem/direct.sh',
             'scripts/suite-runner.js', 'buildSystem/fg-built.js'];
const NOT = ['buildSystem/commented.js', 'buildSystem/echoed.js', 'buildSystem/hinted.js', 'buildSystem/messaged.js',
             'buildSystem/launched-by-message.js', 'scripts/orphan.js', 'buildSystem/tested.js', 'buildSystem/then-echoed.js',
             'buildSystem/assigned-only.js', 'buildSystem/removed.js', 'buildSystem/heredoc.js', 'buildSystem/multiline-echoed.js',
             'buildSystem/cli-tool.js', 'buildSystem/echo-unquoted.js', 'buildSystem/env-assigned.js'];
for (const f of RUN) t.check(runs.has(f), `with fg: ${f} RUNS`, `run set ${JSON.stringify([...runs])}`);
for (const f of NOT) t.check(!runs.has(f), `with fg: ${f} is only named, never run`);
t.check(withFg.fgPresent === true, 'fgPresent is true when the umbrella has fg');
const howOf = (r) => withFg.how.get(path.join(root, 'Fizzygum', r));
t.check(howOf('buildSystem/lib/both.js') === 'launched',
  'a module some runner also LAUNCHES reads launched, though a require reached it first', `how: ${howOf('buildSystem/lib/both.js')}`);
t.check(howOf('buildSystem/lib/used.js') === 'required', 'a module only required reads required', `how: ${howOf('buildSystem/lib/used.js')}`);
t.check(howOf('build_it_please.sh') === 'root', 'the build reads root');

fs.unlinkSync(layout.fg);
const noFg = new Set(rel(runSet(layout).files));
for (const f of ['buildSystem/gate.js', 'buildSystem/alpha-selftest.js', 'scripts/piped.sh']) t.check(noFg.has(f), `without fg: ${f} still RUNS (the build reaches it)`);
for (const f of ['scripts/leg.sh', 'scripts/runner.js', 'buildSystem/beta-selftest-headless.js', 'scripts/q/y-prelude.js']) {
  t.check(!noFg.has(f), `without fg: ${f} is not run (only a leg or the --headless runner reaches it)`);
}

t.check(discover('selftest', layout).map((f) => path.basename(f)).join() === 'alpha-selftest.js', 'discover(selftest) finds exactly the -selftest.js file');
t.check(discover('prelude', layout).length === 2, 'discover(prelude) finds both preludes');
t.check(shellInvocations('a && echo "x.js" ; node y.js | tee z.log').map((i) => i.token).join() === 'y.js',
  'shellInvocations splits a line into commands and skips the printing one');

write('Fizzygum/build_it_please.sh', 'echo "nothing to run here: ./buildSystem/gate.js"\n');
let threw = '';
try { runSet(layout); } catch (e) { threw = e.message; }
t.check(/invokes no scanned script/.test(threw), 'a build script that invokes nothing is an ERROR, never an empty run set', threw);

write('Fizzygum/build_it_please.sh', 'node ./buildSystem/gate.js\n');
write('fg', 'fg_build(){\n  ./build_it_please.sh\n}\nrun_leg(){\n  :\n}\n');
threw = '';
try { runSet(layout); } catch (e) { threw = e.message; }
t.check(/defines no fg_suite, run_lint/.test(threw), "an fg missing any of its four leg functions is an ERROR (a renamed one would drop its legs)", threw);

// THE TOOLING'S OWN FILES (scriptFiles): every root, never a dot entry, a node_modules or a __pycache__, a symlink refused
write('Fizzygum/scripts/vendor-step.sh', 'echo vendoring\n');
write('Fizzygum/.hidden-top.sh', 'echo hidden\n');
write('Fizzygum/not-a-script.txt', 'text\n');
write('Fizzygum/buildSystem/__pycache__/cached.py', '');
write('Fizzygum-tests/scripts/.scratch/scratch-selftest.js', '');
write('Fizzygum-tests/scripts/node_modules/dep/index.js', '');
write('Fizzygum-tests/scripts/.dotfile.js', '');
const tooling = scriptFiles(layout).map((f) => path.relative(root, f));
t.check(tooling.includes('Fizzygum/scripts/vendor-step.sh'), "scriptFiles walks Fizzygum's scripts/ (a script the build launches from there is the census's)");
t.check(tooling.includes('Fizzygum/build_it_please.sh') && !tooling.includes('Fizzygum/.hidden-top.sh') && !tooling.includes('Fizzygum/not-a-script.txt'),
  "scriptFiles takes Fizzygum's top-level .sh files and no dot file", tooling.filter((f) => f.split('/').length === 2).join());
for (const skipped of ['Fizzygum/buildSystem/__pycache__/cached.py', 'Fizzygum-tests/scripts/.scratch/scratch-selftest.js',
  'Fizzygum-tests/scripts/node_modules/dep/index.js', 'Fizzygum-tests/scripts/.dotfile.js']) {
  t.check(!tooling.includes(skipped), `scriptFiles never takes ${skipped}`);
}
fs.symlinkSync(path.join(root, 'Fizzygum-tests/scripts/x.js'), path.join(root, 'Fizzygum-tests/scripts/linked.js'));
threw = '';
try { scriptFiles(layout); } catch (e) { threw = e.message; }
t.check(/^TOOLING_TREE_MALFORMED .*linked\.js: a symlink/.test(threw), 'a symlink among the tooling is refused, TOOLING_TREE_MALFORMED naming it', threw);

// its command line: the real tree's list, one per line; anything else is a usage error (exit 2)
const cli = (args) => spawnSync(process.execPath, [path.join(__dirname, 'what-runs.js'), ...args], { encoding: 'utf8' });
const listed = cli(['--list-scripts']);
t.check(listed.status === 0 && listed.stdout.split('\n').some((l) => l.endsWith(path.join('buildSystem', 'lib', 'what-runs.js'))),
  '--list-scripts prints the tooling, itself among it', String(listed.status));
t.check(cli([]).status === 2 && cli(['--list-scripts', 'extra']).status === 2, 'what-runs.js with no or extra arguments is a usage error (exit 2)');

fs.rmSync(root, { recursive: true, force: true });
t.done();

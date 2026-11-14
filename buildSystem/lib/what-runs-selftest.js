'use strict';
// what-runs-selftest.js — lib/what-runs.js on a miniature workspace written to a temp dir: each way a file can be
// NAMED without being run (a comment, an echo, a help message, a Python docstring) must stay out of the run set, and
// each way one is LAUNCHED (a shell command, a pipeline stage, require(), path.join) must come in — through the build,
// fg's legs and the discovering runners.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { runSet, discover, shellInvocations, scriptFiles } = require('./what-runs');
const { spawnSync } = require('child_process');
const t = require('./selftest-verdict').cases('what-runs');

const root = fs.mkdtempSync(path.join(os.tmpdir(), 'what-runs-selftest-'));
const layout = { fizzygum: path.join(root, 'Fizzygum'), tests: path.join(root, 'Fizzygum-tests'), fg: path.join(root, 'Fizzygum', 'fg') };
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
// the build's own pre-commit check is a root too: what it launches runs, with or without fg
write('Fizzygum/build_and_smoke.sh', './build_it_please.sh "$@"\nnode ../Fizzygum-tests/scripts/smoked.js $SMOKE_ARGS\n');
write('Fizzygum-tests/scripts/smoked.js', '// a smoke\n');
write('Fizzygum-tests/scripts/orphan.js', '');
write('Fizzygum-tests/scripts/leg.sh', 'node scripts/runner.js --audit-prelude="$PWD/scripts/p/x-prelude.js"\nnode "$FZ/buildSystem/lib/both.js"\n');
write('Fizzygum-tests/scripts/runner.js', '');
write('Fizzygum-tests/scripts/suite-runner.js', '');
write('Fizzygum-tests/scripts/p/x-prelude.js', '');
write('Fizzygum-tests/scripts/q/y-prelude.js', '');
write('Fizzygum-tests/scripts/preludes-install-selftest-headless.js', '');
write('Fizzygum/fg', [
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
             'scripts/suite-runner.js', 'buildSystem/fg-built.js', 'build_and_smoke.sh', 'scripts/smoked.js'];
const NOT = ['buildSystem/commented.js', 'buildSystem/echoed.js', 'buildSystem/hinted.js', 'buildSystem/messaged.js',
             'buildSystem/launched-by-message.js', 'scripts/orphan.js', 'buildSystem/tested.js', 'buildSystem/then-echoed.js',
             'buildSystem/assigned-only.js', 'buildSystem/removed.js', 'buildSystem/heredoc.js', 'buildSystem/multiline-echoed.js',
             'buildSystem/cli-tool.js', 'buildSystem/echo-unquoted.js', 'buildSystem/env-assigned.js'];
for (const f of RUN) t.check(runs.has(f), `with fg: ${f} RUNS`, `run set ${JSON.stringify([...runs])}`);
for (const f of NOT) t.check(!runs.has(f), `with fg: ${f} is only named, never run`);
const howOf = (r) => withFg.how.get(path.join(root, 'Fizzygum', r));
t.check(howOf('buildSystem/lib/both.js') === 'launched',
  'a module some runner also LAUNCHES reads launched, though a require reached it first', `how: ${howOf('buildSystem/lib/both.js')}`);
t.check(howOf('buildSystem/lib/used.js') === 'required', 'a module only required reads required', `how: ${howOf('buildSystem/lib/used.js')}`);
t.check(howOf('build_it_please.sh') === 'root', 'the build reads root');
t.check(howOf('build_and_smoke.sh') === 'root', 'the build-and-smoke check reads root', `how: ${howOf('build_and_smoke.sh')}`);
t.check(withFg.how.get(path.join(root, 'Fizzygum-tests', 'scripts/smoked.js')) === 'launched', 'what the build-and-smoke check runs reads launched');

const fgText = fs.readFileSync(layout.fg, 'utf8');
fs.unlinkSync(layout.fg);
let noFg = '';
try { runSet(layout); } catch (e) { noFg = e.message; }
t.check(/^what-runs: no .*Fizzygum\/fg$/.test(noFg), 'a layout without fg is an ERROR, as one without the build is: its legs are always read', noFg);
fs.writeFileSync(layout.fg, fgText);

t.check(discover('selftest', layout).map((f) => path.basename(f)).join() === 'alpha-selftest.js', 'discover(selftest) finds exactly the -selftest.js file');
t.check(discover('prelude', layout).length === 2, 'discover(prelude) finds both preludes');
t.check(shellInvocations('a && echo "x.js" ; node y.js | tee z.log').map((i) => i.token).join() === 'y.js',
  'shellInvocations splits a line into commands and skips the printing one');

write('Fizzygum/build_it_please.sh', 'echo "nothing to run here: ./buildSystem/gate.js"\n');
let threw = '';
try { runSet(layout); } catch (e) { threw = e.message; }
t.check(/invokes no scanned script/.test(threw), 'a build script that invokes nothing is an ERROR, never an empty run set', threw);

write('Fizzygum/build_it_please.sh', 'node ./buildSystem/gate.js\n');
write('Fizzygum/fg', 'fg_build(){\n  ./build_it_please.sh\n}\nrun_leg(){\n  :\n}\n');
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

// THE GATE TABLE: a second miniature build whose shell launches only the runner; the gates are the rows of its
// buildSystem/gates.js, each a launch by the line the runner gives it -- so run-selftests.js launched by a row
// discovers the node-tier self-tests (the table's text also names it, but a JS edge applies no line-keyed
// convention), a row handed the build's arguments is launched too, a row whose script no text scan can name is
// launched (the table is read as data), and a script named in a comment of the table is not. The layout is reached
// through a SYMLINK, which `require` resolves, so a row is read back as the build's shell would spell it. A row
// whose script lives in the tests repo is launched like any other, and is an error like any other when its script
// is missing: the build requires that repo, so nothing passes its rows over.
// Then: a table its build does not run gates nothing, and a row naming a script nothing scans is an error.
const real2 = fs.mkdtempSync(path.join(os.tmpdir(), 'what-runs-selftest-table-'));
const root2 = `${real2}-link`;
fs.symlinkSync(real2, root2);
const layout2 = { fizzygum: path.join(root2, 'Fizzygum'), tests: path.join(root2, 'Fizzygum-tests'), fg: path.join(root2, 'Fizzygum', 'fg') };
const write2 = (rel, text) => { const p = path.join(root2, rel); fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, text); };
const RUNS_THE_RUNNER = 'node ./buildSystem/run-gates.js --noSyntaxCheck=false --shipsTests=true -- "${args[@]}"\n';
const table2 = (rows) => write2('Fizzygum/buildSystem/gates.js', [
  "const path = require('path');",
  "const BUILD_ARGS = 'BUILD_ARGS';",
  "const TESTS_REPO = path.join(__dirname, '..', '..', 'Fizzygum-tests');",
  '// node ./buildSystem/commented-in-table.js',
  'const GATES = [',
  ...rows.map((r) => `  { script: ${r}, args: [], when: 'checked', banner: 'b', failure: 'f' },`),
  "  { script: path.join(__dirname, 'args-gate.js'), args: BUILD_ARGS, when: 'checked', banner: 'b', failure: 'f' },",
  "  { script: path.join(TESTS_REPO, 'scripts', 'tests-gate.js'), args: [], when: 'checked', banner: 'b', failure: 'f' },",
  '];',
  'module.exports = { GATES, BUILD_ARGS, TESTS_REPO };',
].join('\n'));
const ROWS = ["path.join(__dirname, 'run-selftests.js')", "path.join(__dirname, ['table', 'gate'].join('-') + '.js')"];
write2('Fizzygum/build_it_please.sh', RUNS_THE_RUNNER);
write2('Fizzygum/buildSystem/run-gates.js', "const { GATES } = require('./gates');\n");
write2('Fizzygum/fg', 'fg_build(){\n  :\n}\nfg_suite(){ :; }\nrun_lint(){\n  :\n}\nrun_leg(){\n  :\n}\n');   // legs that launch nothing
table2(ROWS);
for (const f of ['run-selftests.js', 'table-gate.js', 'args-gate.js', 'commented-in-table.js', 'other.js', 'gamma-selftest.js']) write2(`Fizzygum/buildSystem/${f}`, '');
write2('Fizzygum-tests/scripts/tests-gate.js', '');
const viaTable = runSet(layout2);
const kind2 = (f) => viaTable.how.get(path.join(root2, 'Fizzygum', f));
t.check(kind2('buildSystem/run-gates.js') === 'launched' && kind2('buildSystem/gates.js') === 'required',
  'the build launches the runner, which requires the table', `${kind2('buildSystem/run-gates.js')} / ${kind2('buildSystem/gates.js')}`);
t.check(kind2('buildSystem/table-gate.js') === 'launched',
  'a row whose script no text scan can name is launched: the table is read as data, through a symlinked layout', String(kind2('buildSystem/table-gate.js')));
t.check(kind2('buildSystem/run-selftests.js') === 'launched' && kind2('buildSystem/args-gate.js') === 'launched',
  'each row of the gate table is a launched script, a BUILD_ARGS row included');
t.check(kind2('buildSystem/gamma-selftest.js') === 'discovered',
  'run-selftests.js launched by a table row discovers the node-tier self-tests', String(kind2('buildSystem/gamma-selftest.js')));
t.check(kind2('buildSystem/commented-in-table.js') === undefined, 'a script named in a comment of the table does not run');
t.check(viaTable.how.get(path.join(root2, 'Fizzygum-tests/scripts/tests-gate.js')) === 'launched',
  'a tests-repo row is a launched script', String(viaTable.how.get(path.join(root2, 'Fizzygum-tests/scripts/tests-gate.js'))));
fs.rmSync(path.join(root2, 'Fizzygum-tests'), { recursive: true, force: true });
let testsRowMissing;
try { runSet(layout2); } catch (e) { testsRowMissing = e.message; }
t.check(/gates\.js has a row for .*Fizzygum-tests\/scripts\/tests-gate\.js, which is not a scanned script/.test(String(testsRowMissing)),
  'a tests-repo row whose script is missing is an ERROR, as any row is: nothing passes it over', String(testsRowMissing));
write2('Fizzygum/build_it_please.sh', 'node ./buildSystem/other.js\n');
const unrun = runSet(layout2).how;
t.check(unrun.get(path.join(root2, 'Fizzygum/buildSystem/table-gate.js')) === undefined
  && unrun.get(path.join(root2, 'Fizzygum/buildSystem/gamma-selftest.js')) === undefined,
  'a table its build does not run gates nothing: its rows are not launched');
write2('Fizzygum/build_it_please.sh', RUNS_THE_RUNNER);
table2([...ROWS, "path.join(__dirname, 'nowhere.js')"]);
let unscanned;
try { runSet(layout2); } catch (e) { unscanned = e.message; }
t.check(/gates\.js has a row for .*nowhere\.js, which is not a scanned script/.test(String(unscanned)),
  'a row naming a script nothing scans is an error, never a gate silently dropped', String(unscanned));
fs.rmSync(root2);
fs.rmSync(real2, { recursive: true, force: true });

// THE LEG TABLE (buildSystem/legs.js): fg's `legs` reader launches it, and its rows are read as data — a row's script
// runs though no text of fg names it, a convention keyed to a row's command line applies (run-selftests.js --headless);
// a row no wave and no presuite schedules, or a step naming no scanned script, is an ERROR; an fg with no reader reads
// no table. The miniature table is legs.js's own code around a small LEGS.
{
  const root3 = fs.mkdtempSync(path.join(os.tmpdir(), 'what-runs-legs-'));
  const layout3 = { fizzygum: path.join(root3, 'Fizzygum'), tests: path.join(root3, 'Fizzygum-tests'), fg: path.join(root3, 'Fizzygum', 'fg') };
  const write3 = (rel, text) => { const p = path.join(root3, rel); fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, text); };
  const legsCode = fs.readFileSync(path.join(__dirname, '..', 'legs.js'), 'utf8');
  const table3 = (rows) => {
    const a = legsCode.indexOf('\nconst LEGS = [\n'), b = legsCode.indexOf('\n];\n', a);
    write3('Fizzygum/buildSystem/legs.js', legsCode.slice(0, a) + '\nconst LEGS = ' + JSON.stringify(rows) + ';\n' + legsCode.slice(b + 4));
  };
  const FG_PARTS = ['fg_build(){\n  :\n}', 'fg_suite(){ ( cd "$FT" && node scripts/run-all-headless.js "$@" ); }', 'run_lint(){\n  :\n}', 'run_leg(){\n  :\n}'];
  const READER = 'legs(){ ( cd "$FZ" && node buildSystem/legs.js --shell "$@" ); }';
  write3('Fizzygum/build_it_please.sh', 'node ./buildSystem/built.js\n');
  for (const f of ['Fizzygum/buildSystem/built.js', 'Fizzygum/buildSystem/run-selftests.js', 'Fizzygum/buildSystem/delta-selftest-headless.js',
    'Fizzygum-tests/scripts/run-all-headless.js', 'Fizzygum-tests/scripts/leg-a.js', 'Fizzygum-tests/scripts/leg-d.js']) write3(f, '');
  const STEP = (cwd, script, ...args) => ({ cwd, alarm: 1, script, args });
  const ROWS3 = [
    { name: 'a', waves: ['A'], steps: [STEP('tests', 'scripts/leg-a.js')], headline: 'x' },
    { name: 'b', waves: ['B'], steps: [STEP('fizzygum', 'buildSystem/run-selftests.js', '--headless')], headline: 'x' },
    { name: 'c', waves: ['C'], steps: [{ suite: ['--dpr=2'] }], headline: 'x' },
    { name: 'd', waves: ['D', 'presuite'], steps: [STEP('tests', 'scripts/leg-d.js', '{GATE_SHARDS}')], headline: 'x' },
  ];
  write3('Fizzygum/fg', [...FG_PARTS, READER].join('\n') + '\n');
  table3(ROWS3);
  const viaLegs = runSet(layout3);
  const of3 = (rel) => viaLegs.how.get(path.join(root3, rel));
  t.check(of3('Fizzygum/buildSystem/legs.js') === 'launched', 'fg\'s legs reader launches the leg table', String(of3('Fizzygum/buildSystem/legs.js')));
  t.check(of3('Fizzygum-tests/scripts/leg-a.js') === 'launched' && of3('Fizzygum-tests/scripts/leg-d.js') === 'launched'
    && viaLegs.why.get(path.join(root3, 'Fizzygum-tests/scripts/leg-a.js')) === 'ROOT: fg legs',
    'a row\'s script is a launch of fg\'s legs, though no text of fg names it', `${of3('Fizzygum-tests/scripts/leg-a.js')} / ${of3('Fizzygum-tests/scripts/leg-d.js')}`);
  t.check(of3('Fizzygum/buildSystem/delta-selftest-headless.js') === 'discovered',
    'a row\'s command line is read for a convention: run-selftests.js --headless discovers the headless self-tests', String(of3('Fizzygum/buildSystem/delta-selftest-headless.js')));
  let threw3 = '';
  table3([...ROWS3, { name: 'idle', waves: [], steps: [STEP('tests', 'scripts/leg-a.js')], headline: 'x' }]);
  try { runSet(layout3); } catch (e) { threw3 = e.message; }
  t.check(/legs\.js cannot be run: leg "idle": no wave and no presuite runs it/.test(threw3),
    'a row no wave and no presuite schedules is an ERROR: it would vouch for a program nothing runs', threw3);
  threw3 = '';
  table3([...ROWS3, { name: 'e', waves: ['A'], steps: [STEP('tests', 'scripts/nowhere.js')], headline: 'x' }]);
  try { runSet(layout3); } catch (e) { threw3 = e.message; }
  t.check(/leg e runs scripts\/nowhere\.js, which is not a scanned script/.test(threw3), 'a step naming no scanned script is an ERROR, never a leg dropped', threw3);
  table3(ROWS3);
  write3('Fizzygum/fg', FG_PARTS.join('\n') + '\n');
  t.check(!runSet(layout3).files.has(path.join(root3, 'Fizzygum-tests/scripts/leg-a.js')), 'an fg with no legs reader reads no table: its rows run nothing');
  fs.rmSync(root3, { recursive: true, force: true });
}

// THE REAL TREE: the build's own gate table and fg's leg table are read -- a renamed runner, reader or table would
// silently stop that, and every node-tier self-test, every leg's program and every headless self-test would read as
// never run
{
  const real = runSet();
  const bs = path.join(__dirname, '..');
  t.check(real.how.get(path.join(bs, 'run-gates.js')) === 'launched' && real.how.get(path.join(bs, 'gates.js')) === 'required'
    && real.how.get(path.join(bs, 'run-gates-selftest.js')) === 'discovered',
    'on the real tree, the build launches the gate runner and the node-tier self-tests are discovered through its table',
    `${real.how.get(path.join(bs, 'run-gates.js'))} / ${real.how.get(path.join(bs, 'gates.js'))} / ${real.how.get(path.join(bs, 'run-gates-selftest.js'))}`);
  const scripts = path.join(path.dirname(path.resolve(bs, '..')), 'Fizzygum-tests', 'scripts');
  t.check(real.how.get(path.join(bs, 'legs.js')) === 'launched' && real.how.get(path.join(scripts, 'revisit-gate.js')) === 'launched'
    && real.how.get(path.join(scripts, 'revisit-gate-selftest-headless.js')) === 'discovered',
    'on the real tree, fg launches its leg table, a leg\'s program is launched through it, and the headless self-tests are discovered',
    `${real.how.get(path.join(bs, 'legs.js'))} / ${real.how.get(path.join(scripts, 'revisit-gate.js'))} / ${real.how.get(path.join(scripts, 'revisit-gate-selftest-headless.js'))}`);
}

// its command line: the real tree's list, one per line; anything else is a usage error (exit 2)
const cli = (args) => spawnSync(process.execPath, [path.join(__dirname, 'what-runs.js'), ...args], { encoding: 'utf8' });
const listed = cli(['--list-scripts']);
t.check(listed.status === 0 && listed.stdout.split('\n').some((l) => l.endsWith(path.join('buildSystem', 'lib', 'what-runs.js'))),
  '--list-scripts prints the tooling, itself among it', String(listed.status));
t.check(cli([]).status === 2 && cli(['--list-scripts', 'extra']).status === 2, 'what-runs.js with no or extra arguments is a usage error (exit 2)');

fs.rmSync(root, { recursive: true, force: true });
t.done();

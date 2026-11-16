#!/usr/bin/env node
'use strict';
// run-build-selftest.js — the cases of the build's sequencing (run-build.js, through its launcher build_it_please.sh)
// and of build_and_smoke's (run-build-and-smoke.js) that no real build exercises on demand. A COPY of both launchers and
// both modules, with lib/profile.js and lib/write-all.js, runs in a planted `Fizzygum-all` in a temp dir (outside any
// git repo, so the stamp reads `no-git`), beside the real profiles, partition and boot files, with stand-in tools: the
// build's programs as small node scripts that do or fail as a case plants, the compiler and the minifier, and an `rm`
// first on PATH that fails the one call a case names (every other call is the real rm). It holds:
//   - a green build of a compile-at-boot profile and of the appliance: exit 0, `done!!!` last; the tree; the tests link
//     made (or, for the appliance, absent) and the sentinel behind it untouched; the fonts copied without their
//     top-level dot entry; the stamp carrying the start marker's time, which the record's first line states;
//   - one exit of each kind: an argument refused, the layout, the toolchain, the profile, a launched utility that fails,
//     the assembly, a gate, the boot's minifier, the pre-compile driver (its line WITHOUT the bell), the appliance's
//     missing layer script, the start marker gone at the end — each its text on its stream, exit 1, no stamp;
//   - the cleaner's refusals: a tree that is not ../Fizzygum-builds/latest, a removal spelled with a trailing slash;
//   - build_and_smoke's flag for each real profile, and its run end to end once.
// The bash script this build replaced was compared with it on every exit and green path, byte for byte
// (docs/archive/build-node-port-plan.md, P4); this keeps the shape that comparison proved.
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const t = require('./lib/selftest-verdict').cases('run-build');

const FZ_REAL = path.resolve(__dirname, '..');
const PARENT = fs.mkdtempSync(path.join(os.tmpdir(), 'run-build-selftest-'));
const U = path.join(PARENT, 'Fizzygum-all'), FZ = path.join(U, 'Fizzygum'), T = path.join(U, 'Fizzygum-builds', 'latest');
const BIN = path.join(PARENT, 'bin');

const write = (p, text, mode) => { fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, text); if (mode) fs.chmodSync(p, mode); };
const PLANTED = (id) => `((process.env.RUN_BUILD_PLANT || '') === ${JSON.stringify(id)})`;
const tool = (body) => "#!/usr/bin/env node\n'use strict';\nconst fs = require('fs'), path = require('path');\n" + body;
const VERSIONS = { coffeescript: '2.7.0', terser: '5.31.0', acorn: '8.19.0', 'coffeescript-cognitive-complexity': '1.0.0' };

// a fresh planted layout, with a previous build's tree in it
function plant(setup) {
  fs.rmSync(U, { recursive: true, force: true });
  for (const f of ['build_it_please.sh', 'build_and_smoke.sh']) write(path.join(FZ, f), fs.readFileSync(path.join(FZ_REAL, f)), 0o755);
  for (const f of ['run-build.js', 'run-build-and-smoke.js', 'lib/profile.js', 'lib/write-all.js', 'parts.json']) {
    write(path.join(FZ, 'buildSystem', f), fs.readFileSync(path.join(FZ_REAL, 'buildSystem', f)));
  }
  fs.cpSync(path.join(FZ_REAL, 'buildSystem', 'profiles'), path.join(FZ, 'buildSystem', 'profiles'), { recursive: true });
  fs.cpSync(path.join(FZ_REAL, 'src', 'boot'), path.join(FZ, 'src', 'boot'), { recursive: true });
  write(path.join(FZ, 'package.json'), JSON.stringify({ devDependencies: VERSIONS }));
  for (const [n, v] of Object.entries(VERSIONS)) write(path.join(FZ, 'node_modules', n, 'package.json'), JSON.stringify({ version: v }));
  write(path.join(FZ, 'node_modules/coffeescript/bin/coffee'), tool(
    "const a = process.argv.slice(2);\nif (a[0] === '--version') { console.log('CoffeeScript version 9'); process.exit(0); }\n" +
    "const file = a[a.length - 1];\nfs.writeFileSync(path.join(a[a.indexOf('-o') + 1], path.basename(file, '.coffee') + '.js'), fs.readFileSync(file));\n"), 0o755);
  write(path.join(FZ, 'node_modules/terser/bin/terser'), tool(
    "const a = process.argv.slice(2), o = a[a.indexOf('--output') + 1];\n" +
    `if (${PLANTED('terser-boot')} && o.endsWith('fizzygum-boot-min.js')) { console.error('ERROR: planted'); process.exit(1); }\n` +
    `if (${PLANTED('no-layer')} && o.endsWith('dependencies-finding-min.js')) process.exit(0);\n` +
    "fs.writeFileSync(o, fs.readFileSync(a[a.length - 1]));\n"), 0o755);
  write(path.join(FZ, 'buildSystem/lib/build-inputs.js'), tool(
    "process.stdout.write('# build started at ' + fs.statSync(process.argv[3]).mtimeMs + '\\n');\n"));
  write(path.join(FZ, 'buildSystem/build.js'), tool(
    `if (${PLANTED('build.js')}) { console.error('build.js: planted'); process.exit(1); }\n` +
    "fs.writeFileSync('../Fizzygum-builds/latest/delete_me/partsManifest.coffee', '\\n');\n" +
    "fs.writeFileSync('../Fizzygum-builds/latest/index.html', '');\nfs.writeFileSync('../Fizzygum-builds/latest/js/coffeescript-sources/b.js', '');\n"));
  write(path.join(FZ, 'buildSystem/run-gates.js'), tool(
    `if (${PLANTED('gate')}) { console.error('[gate] FAIL planted'); process.exit(1); }\n` +
    `if (${PLANTED('no-start')}) fs.unlinkSync('../Fizzygum-builds/latest/.build-start');\n`));
  for (const f of ['swcanvas.min.js', 'sw3d.js', 'swcanvas-3d-core.min.js', 'sw3d.min.js']) write(path.join(FZ, 'vendor/swcanvas', f), f);
  write(path.join(FZ, 'vendor/swcanvas/VERSION'), 'PIN\n');
  write(path.join(FZ, 'vendor/swcanvas.pin'), 'PIN\n');
  write(path.join(FZ, 'runtime-prelude/deterministic-trig.js'), 'trig');
  write(path.join(FZ, 'assets/pre-compiled.js'), 'window.preCompiled = false;\n');
  write(path.join(FZ, 'font-assets/a.json'), 'A');
  write(path.join(FZ, 'font-assets/.DS_Store'), 'never copied');
  write(path.join(U, 'Fizzygum-tests/tests/SENTINEL'), 'the real suite');
  write(path.join(U, 'Fizzygum-tests/scripts/generate-tests-manifests.js'), tool(''));
  write(path.join(U, 'Fizzygum-tests/scripts/generate-pre-compiled-headless.js'), tool(
    `if (${PLANTED('driver')}) { console.error('driver: planted'); process.exit(1); }\n` +
    "fs.writeFileSync('../Fizzygum-builds/latest/js/pre-compiled.js', 'window.preCompiled = true;\\n');\n"));
  write(path.join(U, 'Fizzygum-tests/scripts/smoke-boot-headless.js'), tool("console.log('smoke [' + process.argv.slice(2).join(' ') + ']');\n"));
  // a previous build: its pages, its js with the tests link, its stamp
  fs.mkdirSync(path.join(T, 'js'), { recursive: true });
  fs.symlinkSync('../../../Fizzygum-tests/tests', path.join(T, 'js/tests'));
  write(path.join(T, 'old.html'), '');
  write(path.join(T, '.build-stamp'), '');
  if (setup) setup();
}
// `rm` first on PATH: the call whose arguments match RUN_BUILD_RM fails, every other is the real one
write(path.join(BIN, 'rm'), '#!/bin/sh\nif [ -n "$RUN_BUILD_RM" ] && [ "$*" = "$RUN_BUILD_RM" ]; then echo "rm: planted ($*)" >&2; exit 1; fi\nexec /bin/rm "$@"\n', 0o755);

// one run of a launcher in the planted layout → { rc, out, err }
function run(script, args = [], env = {}, setup) {
  plant(setup);
  // (no inherited GIT_* variable: the planted build must not find a repository, so its stamp reads `no-git`)
  const base = Object.fromEntries(Object.entries(process.env).filter(([k]) => !k.startsWith('GIT_')));
  const r = spawnSync('./' + script, args, { cwd: FZ, encoding: 'utf8',
    env: { ...base, PATH: `${BIN}:${path.dirname(process.execPath)}:/usr/bin:/bin`, TERM: 'dumb', ...env } });
  return { rc: r.status, out: r.stdout, err: r.stderr };
}
const exists = (p) => { try { fs.lstatSync(p); return true; } catch (e) { return false; } };
// the last line of a stream, without the bell (`tput bel` writes BEL even on a dumb terminal)
const lastLine = (s) => s.replace(/\x07/g, '').trimEnd().split('\n').pop();

try {
  // ---- green ----
  let r = run('build_it_please.sh', ['--profile', 'dev']);
  const recorded = fs.existsSync(path.join(FZ, '.latest-build-inputs')) && /^# build started at ([0-9.]+)/.exec(fs.readFileSync(path.join(FZ, '.latest-build-inputs'), 'utf8'));
  t.check(r.rc === 0 && r.out.endsWith('\x07done!!!!!!!!!!!!\n') && r.err === ''
    && fs.readlinkSync(path.join(T, 'js/tests')) === '../../../Fizzygum-tests/tests' && exists(path.join(U, 'Fizzygum-tests/tests/SENTINEL'))
    && !exists(path.join(T, 'old.html')) && exists(path.join(T, 'js/fizzygum-boot-sw-min.js')) && exists(path.join(T, 'js/fizzygum-boot-native-min.js'))
    && !exists(path.join(T, 'js/fizzygum-boot-min.js')) && !exists(path.join(T, 'delete_me')) && !exists(path.join(T, '.build-start'))
    && exists(path.join(T, 'font-assets/a.json')) && !exists(path.join(T, 'font-assets/.DS_Store'))
    && recorded && Math.abs(fs.statSync(path.join(T, '.build-stamp')).mtimeMs - Number(recorded[1])) < 0.001
    && /^;var buildVersion='Fizzygum no-git \(unknown-date\)';$/m.test(fs.readFileSync(path.join(T, 'js/fizzygum-boot-native-min.js'), 'utf8')),
  'a green dev build: the bell then done, the tests link made and the suite behind it untouched, the fonts without their top-level dot entry, the stamp at the start marker\'s time',
  JSON.stringify(r));
  r = run('build_it_please.sh', ['--profile', 'lean']);
  t.check(r.rc === 0 && lastLine(r.out) === 'done!!!!!!!!!!!!' && !exists(path.join(T, 'js/tests')) && exists(path.join(U, 'Fizzygum-tests/tests/SENTINEL'))
    && !exists(path.join(T, 'font-assets')) && !exists(path.join(T, 'js/fizzygum-boot-sw-min.js')) && !exists(path.join(T, 'js/coffeescript-sources'))
    && !exists(path.join(T, 'js/src/dependencies-finding-min.js')) && fs.readFileSync(path.join(T, 'js/pre-compiled.js'), 'utf8') === 'window.preCompiled = true;\n'
    && exists(path.join(T, '.build-stamp')),
  'a green appliance build: no tests link (the suite untouched), no fonts, no SW bundle, no source text, no layer script, the image in place',
  JSON.stringify(r));

  // ---- one exit of each kind: its text (the last line of its stream), exit 1; an exit before the clean leaves the
  // previous build's stamp, one after it none ----
  // (`bell`: the bell rings last on stdout — a step that failed says so with the bell, its line on stderr)
  const exitCase = (what, script, args, env, setup, stream, text, beforeClean = false, bell = false) => {
    const x = run(script, args, env, setup);
    t.check(x.rc === 1 && lastLine(x[stream]) === text && exists(path.join(T, '.build-stamp')) === beforeClean && (!bell || x.out.endsWith('\x07')),
      what, JSON.stringify(x));
  };
  exitCase('an argument refused', 'build_it_please.sh', ['--homepage'], {}, undefined, 'err', '  Other options: --noSyntaxCheck', true);
  exitCase('--profile needs a name', 'build_it_please.sh', ['--profile'], {}, undefined, 'err', 'build_it_please.sh: --profile needs a name, e.g. --profile homepage', true);
  exitCase('no tests repo: the layout block on stdout', 'build_it_please.sh', [], {}, () => fs.rmSync(path.join(U, 'Fizzygum-tests'), { recursive: true }),
    'out', 'Check it out beside this repo, inside Fizzygum-all.', true);
  exitCase('a toolchain pin differs, on stdout', 'build_it_please.sh', [], {}, () => write(path.join(FZ, 'node_modules/acorn/package.json'), '{"version":"1"}'),
    'out', 'acorn in Fizzygum/node_modules is 1, not the 8.19.0 package.json pins: run npm ci in Fizzygum/.', true);
  r = run('build_it_please.sh', ['--profile', 'nosuch']);
  t.check(r.rc === 1 && /^profile\.js: no such profile 'nosuch'/.test(r.err) && lastLine(r.err) === '!!!!!!!!!!! error: could not read the build profile -- aborting build.'
    && exists(path.join(T, '.build-stamp')),
    'a profile refused: the reader\'s words, then the build\'s line', JSON.stringify(r));
  exitCase('a launched utility that fails (rm of js/): the bell, then its line', 'build_it_please.sh', [], { RUN_BUILD_RM: '-rf ../Fizzygum-builds/latest/js' }, undefined,
    'err', '!!!!!!!!!!! error: removing the previous js tree failed', false, true);
  exitCase('the assembly fails', 'build_it_please.sh', [], { RUN_BUILD_PLANT: 'build.js' }, undefined, 'err', '!!!!!!!!!!! error: buildSystem/build.js failed -- aborting build.');
  exitCase('a gate fails: the runner said why', 'build_it_please.sh', [], { RUN_BUILD_PLANT: 'gate' }, undefined, 'err', '[gate] FAIL planted');
  exitCase('the boot\'s minifier fails', 'build_it_please.sh', [], { RUN_BUILD_PLANT: 'terser-boot' }, undefined, 'err', '!!!!!!!!!!! error: minifying the boot file failed!');
  r = run('build_it_please.sh', ['--profile', 'homepage'], { RUN_BUILD_PLANT: 'driver' });
  t.check(r.rc === 1 && lastLine(r.err) === '!!!!!!!!!!! error: pre-compiled generation failed' && !exists(path.join(T, '.build-stamp'))
    && r.out.endsWith('generating the pre-compiled file headlessly. this might take a few seconds...\n'),
    'the pre-compile driver fails: its line, and nothing on stdout after the driver started (no bell)', JSON.stringify(r));
  exitCase('the appliance\'s layer script was not built', 'build_it_please.sh', ['--profile', 'lean'], { RUN_BUILD_PLANT: 'no-layer' }, undefined, 'err',
    "!!!!!!!!!!! error: dropping the reflective layer's boot script (js/src/dependencies-finding-min.js was not built: renamed?) failed");
  exitCase('the start marker gone at the end', 'build_it_please.sh', [], { RUN_BUILD_PLANT: 'no-start' }, undefined, 'err',
    '!!!!!!!!!!! error: could not write the build stamp (no .build-start: another build in this tree?)');

  // ---- the cleaner's refusals, before anything is removed ----
  plant();
  const refuse = (call) => spawnSync(process.execPath, ['-e', `const b = require(${JSON.stringify(path.join(FZ, 'buildSystem/run-build.js'))});\n` +
    `try { ${call}; } catch (e) { process.exit(e instanceof b.Stop ? 3 : 4); }`], { cwd: FZ, encoding: 'utf8', env: { ...process.env, PATH: `${BIN}:${process.env.PATH}` } });
  const elsewhere = path.join(PARENT, 'elsewhere', 'latest');
  write(path.join(elsewhere, 'kept'), 'kept');
  let c = refuse(`b.clean(${JSON.stringify(elsewhere)})`);
  t.check(c.status === 3 && /refusing to clean .*elsewhere\/latest/.test(c.stderr) && exists(path.join(elsewhere, 'kept')),
    'a tree that is not ../Fizzygum-builds/latest is refused, nothing removed', c.status + c.stderr);
  c = refuse("b.removeTree('../Fizzygum-builds/latest/js/', 'x')");
  t.check(c.status === 3 && /trailing slash/.test(c.stderr) && exists(path.join(T, 'js/tests')) && exists(path.join(U, 'Fizzygum-tests/tests/SENTINEL')),
    'a removal spelled with a trailing slash is refused: the link and the suite stand', c.status + c.stderr);

  // ---- build_and_smoke ----
  const { smokeFor } = require(path.join(FZ, 'buildSystem/run-build-and-smoke.js'));
  const { resolve } = require(path.join(FZ, 'buildSystem/lib/profile.js'));
  const prev = process.cwd();
  process.chdir(FZ);
  const flags = Object.fromEntries(['dev', 'dev-notests', 'dev-precompiled', 'homepage', 'lean'].map((p) => [p, smokeFor(resolve(p)).flag]));
  process.chdir(prev);
  t.check(JSON.stringify(flags) === JSON.stringify({ dev: undefined, 'dev-notests': '--no-harness-page', 'dev-precompiled': '--production', homepage: '--production', lean: '--lean' }),
    "build_and_smoke's smoke flag for each real profile", JSON.stringify(flags));
  r = run('build_and_smoke.sh', ['--profile', 'lean']);
  t.check(r.rc === 0 && r.out.startsWith('(profile lean is an appliance build -> boot smoke runs the production assertions + no-source-text)\n==> building')
    && r.out.includes('\nsmoke [--lean]\n') && lastLine(r.out) === 'build_and_smoke: OK (build + boot smoke passed).',
    'build_and_smoke end to end: its line, the build, the smoke with its flag, OK', JSON.stringify(r));
} catch (e) { t.check(false, 'the cases ran to their end', e.stack); }
finally { fs.rmSync(PARENT, { recursive: true, force: true }); }
t.done();

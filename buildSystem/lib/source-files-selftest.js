'use strict';
// source-files-selftest.js — the compiled sources' one definition (lib/source-files.js), on throwaway trees: a .coffee
// file in a dot directory, in a node_modules and named with a leading dot is READ (the coverage gate is what fails one
// that ships nothing), a non-.coffee file is not, and the order is code point; a symlinked file and a symlinked
// directory are each REFUSED naming the link, and so are a missing root, a file named as a root and a root holding no
// .coffee file; the harness is undefined for a path holding no tests repo (a fixture reading src alone) and refused when
// a tests repo has none; compiledFiles is src's then the harness's; sourceName names each by its tree; sourceRoots reads
// the two rails, and refuses (exit 2) a workspace without the sibling tests repo unless a rail names one — seen on a copy
// of this library placed where no tests repo stands beside it. Run by buildSystem/run-selftests.js on every build.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const { coffeeFilesIn, harnessFiles, compiledFiles, sourceName, sourceRoots, byCodePoint, SRC, TESTS_REPO, HARNESS_DIR } = require('./source-files');
const t = require('./selftest-verdict').cases('source-files');

const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'source-files-selftest-'));
process.on('exit', () => fs.rmSync(temp, { recursive: true, force: true }));
const at = (rel) => path.join(temp, rel);
const put = (rel, text = 'x = 1\n') => { fs.mkdirSync(path.dirname(at(rel)), { recursive: true }); fs.writeFileSync(at(rel), text); };
const refusal = (fn) => { try { fn(); return ''; } catch (e) { return e.message; } };

// every .coffee file is read, whatever its directory or its name
const READ = ['src/B.coffee', 'src/a-b.coffee', 'src/a/z.coffee', 'src/A.coffee', 'src/.hidden/D.coffee',
  'src/node_modules/N.coffee', 'src/x/.dot.coffee'];
READ.forEach((rel) => put(rel));
put('src/notes.txt', 'not a source\n');
const got = coffeeFilesIn(at('src'));
const want = READ.map(at).sort(byCodePoint);
t.check(JSON.stringify(got) === JSON.stringify(want),
  'every .coffee file is read — in a dot directory, in a node_modules, named with a leading dot — and nothing else, in code-point order',
  got.map((p) => path.relative(temp, p)).join(' '));
t.check(got.indexOf(at('src/a-b.coffee')) < got.indexOf(at('src/a/z.coffee')),
  'the order is the code-point order of the whole path (`a-b.coffee` before `a/z.coffee`), not a directory-by-directory listing');

// refused, each naming what it refuses
fs.cpSync(at('src'), at('fileLink'), { recursive: true });
fs.symlinkSync(at('src/A.coffee'), at('fileLink/a/L.coffee'));
const fileLink = refusal(() => coffeeFilesIn(at('fileLink')));
t.check(fileLink.startsWith(`SOURCE_TREE_MALFORMED ${at('fileLink/a/L.coffee')}: a symlink`), 'a symlinked file is refused, naming the link', fileLink || 'read');
fs.cpSync(at('src'), at('dirLink'), { recursive: true });
put('elsewhere/E.coffee');
fs.symlinkSync(at('elsewhere'), at('dirLink/linkedDir'));
const dirLink = refusal(() => coffeeFilesIn(at('dirLink')));
t.check(dirLink.startsWith(`SOURCE_TREE_MALFORMED ${at('dirLink/linkedDir')}: a symlink`), 'a symlinked directory is refused, naming the link', dirLink || 'read');
fs.cpSync(at('src'), at('otherLink'), { recursive: true });
fs.symlinkSync(at('src/notes.txt'), at('otherLink/notes-too.txt'));
const otherLink = refusal(() => coffeeFilesIn(at('otherLink')));
t.check(otherLink.startsWith(`SOURCE_TREE_MALFORMED ${at('otherLink/notes-too.txt')}: a symlink`), 'a symlink to a file that is no source is refused too: the tree holds no link at all', otherLink || 'read');
const missing = refusal(() => coffeeFilesIn(at('nowhere')));
t.check(missing === `SOURCE_TREE_MALFORMED ${at('nowhere')}: there is no such directory`, 'a missing root is refused', missing || 'read');
const fileRoot = refusal(() => coffeeFilesIn(at('src/A.coffee')));
t.check(fileRoot === `SOURCE_TREE_MALFORMED ${at('src/A.coffee')}: it is a file, not a directory`, 'a file named as the root is refused', fileRoot || 'read');
put('empty/notes.txt', 'no source here\n');
const empty = refusal(() => coffeeFilesIn(at('empty')));
t.check(empty.startsWith(`SOURCE_TREE_MALFORMED ${at('empty')}: it holds no .coffee file`), 'a root holding no .coffee file is refused', empty || 'read');

// the harness, beside src: undefined for a path holding no tests repo (a fixture reading src alone), refused when a
// tests repo has none, then src's and the harness's
t.check(harnessFiles(at('noRepo')) === undefined, 'a path holding no tests repo has no harness (undefined)');
t.check(JSON.stringify(compiledFiles({ src: at('src'), testsRepo: at('noRepo') })) === JSON.stringify(want), 'for a path holding no tests repo the compiled files are src\'s alone');
put('repoWithoutHarness/scripts/s.js', 's()\n');
const noHarness = refusal(() => harnessFiles(at('repoWithoutHarness')));
t.check(noHarness === `SOURCE_TREE_MALFORMED ${at('repoWithoutHarness/' + HARNESS_DIR)}: there is no such directory`,
  'a tests repo without a harness is refused', noHarness || 'read');
put(`repo/${HARNESS_DIR}/H.coffee`);
put(`repo/${HARNESS_DIR}/Deep/C.coffee`);
const roots = { src: at('src'), testsRepo: at('repo') };
const compiled = compiledFiles(roots);
const harness = [at(`repo/${HARNESS_DIR}/Deep/C.coffee`), at(`repo/${HARNESS_DIR}/H.coffee`)];
t.check(JSON.stringify(compiled) === JSON.stringify([...want, ...harness]), 'the compiled files are src\'s, then the harness\'s, each in code-point order',
  compiled.map((p) => path.relative(temp, p)).join(' '));

// the names a gate prints
const names = [at('src/a/z.coffee'), harness[0]].map((f) => sourceName(f, roots)).join(' ');
t.check(names === 'a/z.coffee harness/Deep/C.coffee', 'sourceName: a src file by its path in src, a harness file under harness/', names);
const prefixed = [at('src/a/z.coffee'), harness[1]].map((f) => sourceName(f, roots, 'src/')).join(' ');
t.check(prefixed === 'src/a/z.coffee harness/H.coffee', 'sourceName with a prefix: the prefix goes on src\'s names only', prefixed);

// the rails
const defaults = sourceRoots([], 'source-files-selftest');
t.check(defaults.src === SRC && defaults.testsRepo === TESTS_REPO, 'with no rail the roots are this umbrella\'s src and tests repo');
const railed = sourceRoots([`--src=${at('src')}`, `--tests-repo=${at('repo')}`], 'source-files-selftest');
t.check(railed.src === at('src') && railed.testsRepo === at('repo'), '--src= and --tests-repo= name the two roots');

// a workspace without the tests repo: this library and the one it requires, copied to Fizzygum/buildSystem/lib/ of a
// workspace with no Fizzygum-tests beside it, asked for its roots with no rail and with a --tests-repo= rail
const lib = at('lonely/Fizzygum/buildSystem/lib');
fs.mkdirSync(lib, { recursive: true });
for (const f of ['source-files.js', 'cli-args.js']) fs.copyFileSync(path.join(__dirname, f), path.join(lib, f));
const rootsIn = (argv) => spawnSync(process.execPath, ['-e',
  `console.log(JSON.stringify(require(${JSON.stringify(path.join(lib, 'source-files.js'))}).sourceRoots(${JSON.stringify(argv)}, 'g')))`],
  { encoding: 'utf8' });
const lonely = rootsIn([]);
t.check(lonely.status === 2 && lonely.stdout === ''
  // (node runs a module from its real path: the temp dir's /var is /private/var on macOS)
  && lonely.stderr.startsWith(`[g] ERROR — the sibling Fizzygum-tests repo is required (at ${path.join(fs.realpathSync(at('lonely')), 'Fizzygum-tests')})`),
  'no rail, and no tests repo beside the workspace: refused, exit 2, naming where it should be — never half the sources',
  `exit ${lonely.status}, out ${JSON.stringify(lonely.stdout)}, err ${JSON.stringify(lonely.stderr)}`);
const named = rootsIn([`--tests-repo=${at('repo')}`]);
t.check(named.status === 0 && JSON.parse(named.stdout || '{}').testsRepo === at('repo'),
  'the same workspace with a --tests-repo= rail reads the repo the rail names', `exit ${named.status}: ${named.stdout}${named.stderr}`);

t.done();

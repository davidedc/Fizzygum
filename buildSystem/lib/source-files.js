'use strict';
// source-files.js — THE CoffeeScript the build compiles, as files: src/ and the sibling tests repo's harness
// (Automator-and-test-harness-src/, the other half of the `harness` part). Every gate and census that reads the compiled
// sources takes its files from here, so no two of them can disagree about which files exist.
//
//   coffeeFilesIn(root)                    every .coffee file under root, absolute, in code-point order
//   srcFiles(src = SRC)                    src's
//   harnessFiles(testsRepo = TESTS_REPO)   the harness's; undefined for a path holding no tests repo (a fixture
//                                          reading src alone)
//   compiledFiles({ src, testsRepo })      src's, then the harness's (src's alone for such a fixture)
//   sourceRoots(argv, name)                { src, testsRepo } from the two rails, SOURCE_RAILS: --src=DIR and
//                                          --tests-repo=DIR (lib/cli-args.js dirArg), each defaulting to this umbrella's;
//                                          the default tests repo missing is refused (exit 2): every build requires it,
//                                          so a gate run by hand outside a workspace holding it says so rather than
//                                          read half the sources
//   sourceName(file, roots, srcPrefix)     the name a gate prints for a file: srcPrefix + its path in src, or
//                                          `harness/` + its path in the harness
//
// The rule is the testNames one (lib/tests-repo-code.js): refuse, never skip. Every .coffee file is read, one in a dot
// directory, in a node_modules or named with a leading dot included: check-shippable-coverage.js fails each such file as
// UNSHIPPED, so none can sit unseen. A SYMLINK anywhere under a root is refused, SOURCE_TREE_MALFORMED naming it: the
// build's own listing (build.js's glob) follows a symlinked file and does not descend a symlinked directory, so a file
// behind a symlink is shipped by a meaning no gate shares, or shipped by nothing and seen by nothing. A root that is
// missing, or that holds no .coffee file, is refused too: a gate that reads no file passes. The order is the code-point
// order of the absolute paths, so no gate's output depends on the file system's listing order.
//
// The partition (buildSystem/parts.json, build.js --list-shippable) answers a different question — which PART ships a
// file — and src/boot's files are declared there apart from it (each part's bootPrelude / bootScripts, build.js
// --list-boot). check-shippable-coverage.js is the one place that holds the files to both.
// Its cases are source-files-selftest.js.

const fs = require('fs');
const path = require('path');
const { dirArg } = require('./cli-args');

const SRC = path.resolve(__dirname, '../../src');
const TESTS_REPO = path.resolve(__dirname, '../../../Fizzygum-tests');
const HARNESS_DIR = 'Automator-and-test-harness-src';
const SOURCE_RAILS = ['--src=', '--tests-repo='];
const byCodePoint = (a, b) => (a < b ? -1 : a > b ? 1 : 0);

function coffeeFilesIn(root) {
  const refuse = (p, why) => { throw new Error(`SOURCE_TREE_MALFORMED ${p}: ${why}`); };
  const top = path.resolve(root);
  let st;
  try { st = fs.statSync(top); } catch (e) { refuse(top, 'there is no such directory'); }
  if (!st.isDirectory()) refuse(top, 'it is a file, not a directory');
  const out = [];
  const walk = (dir) => {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      const p = path.join(dir, e.name);
      if (e.isSymbolicLink()) refuse(p, 'a symlink, which the build\'s listing follows for a file and not for a directory');
      if (e.isDirectory()) walk(p);
      else if (e.name.endsWith('.coffee')) out.push(p);
    }
  };
  walk(top);
  if (!out.length) refuse(top, 'it holds no .coffee file, and a gate that reads no file passes');
  return out.sort(byCodePoint);
}

const srcFiles = (src = SRC) => coffeeFilesIn(src);
// undefined for a path holding no tests repo: a library fixture reading a src miniature alone hands one
// (install-edges-selftest.js, settling-setters-selftest.js). A gate never meets it — sourceRoots refuses a workspace
// without the tests repo, and a rail naming no directory is refused by dirArg.
const harnessFiles = (testsRepo = TESTS_REPO) => (fs.existsSync(testsRepo) ? coffeeFilesIn(path.join(testsRepo, HARNESS_DIR)) : undefined);
const compiledFiles = ({ src = SRC, testsRepo = TESTS_REPO } = {}) => [...srcFiles(src), ...(harnessFiles(testsRepo) || [])];
// THE ONE REFUSAL for a gate run outside the build without the tests repo: the build checks for it before anything else
// (build_it_please.sh), and a gate run by hand meets it here, once for every gate that takes the rails.
function sourceRoots(argv, name) {
  const src = dirArg(argv, '--src=', SRC, name);
  const testsRepo = dirArg(argv, '--tests-repo=', undefined, name);
  if (testsRepo !== undefined) return { src, testsRepo };
  let st;
  try { st = fs.statSync(TESTS_REPO); } catch (e) { st = undefined; }
  if (!st || !st.isDirectory()) {
    console.error(`[${name}] ERROR — the sibling Fizzygum-tests repo is required (at ${TESTS_REPO}): its harness is half `
      + 'the compiled sources, and every build requires it; check it out beside Fizzygum/, or name one with --tests-repo=DIR');
    process.exit(2);
  }
  return { src, testsRepo: TESTS_REPO };
}

function sourceName(file, { testsRepo = TESTS_REPO, src = SRC } = {}, srcPrefix = '') {
  const posix = (p) => p.split(path.sep).join('/');
  const inHarness = path.relative(path.join(testsRepo, HARNESS_DIR), file);
  if (!inHarness.startsWith('..') && !path.isAbsolute(inHarness)) return 'harness/' + posix(inHarness);
  return srcPrefix + posix(path.relative(src, file));
}

module.exports = { coffeeFilesIn, srcFiles, harnessFiles, compiledFiles, sourceRoots, sourceName, SOURCE_RAILS, SRC, TESTS_REPO,
  HARNESS_DIR, byCodePoint };

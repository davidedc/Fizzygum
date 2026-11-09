'use strict';
// source-files.js — THE CoffeeScript the build compiles, as files: src/ and the sibling tests repo's harness
// (Automator-and-test-harness-src/, the other half of the `harness` part). Every gate and census that reads the compiled
// sources takes its files from here, so no two of them can disagree about which files exist.
//
//   coffeeFilesIn(root)                    every .coffee file under root, absolute, in code-point order
//   srcFiles(src = SRC)                    src's
//   harnessFiles(testsRepo = TESTS_REPO)   the harness's; undefined when there is no tests repo at testsRepo
//   compiledFiles({ src, testsRepo })      src's, then the harness's (src's alone when there is no tests repo)
//   sourceRoots(argv, name)                { src, testsRepo } from the two rails, SOURCE_RAILS: --src=DIR and
//                                          --tests-repo=DIR (lib/cli-args.js dirArg), each defaulting to this umbrella's
//   sourceName(file, roots, srcPrefix)     the name a gate prints for a file: srcPrefix + its path in src, or
//                                          `harness/` + its path in the harness
//
// The rule is the testNames one (lib/tests-repo-code.js): refuse, never skip. Every .coffee file is read, one in a dot
// directory, in a node_modules or named with a leading dot included: check-shippable-coverage.js fails each such file as
// UNSHIPPED, so none can sit unseen. A SYMLINK anywhere under a root is refused, SOURCE_TREE_MALFORMED naming it: the
// build's own listing (build.py's glob) follows a symlinked file and does not descend a symlinked directory, so a file
// behind a symlink is shipped by a meaning no gate shares, or shipped by nothing and seen by nothing. A root that is
// missing, or that holds no .coffee file, is refused too: a gate that reads no file passes. The order is the code-point
// order of the absolute paths, so no gate's output depends on the file system's listing order.
//
// The partition (buildSystem/parts.json, build.py --list-shippable) answers a different question — which PART ships a
// file — and src/boot is outside it. check-shippable-coverage.js is the one place that holds the two to each other.
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
const harnessFiles = (testsRepo = TESTS_REPO) => (fs.existsSync(testsRepo) ? coffeeFilesIn(path.join(testsRepo, HARNESS_DIR)) : undefined);
const compiledFiles = ({ src = SRC, testsRepo = TESTS_REPO } = {}) => [...srcFiles(src), ...(harnessFiles(testsRepo) || [])];
const sourceRoots = (argv, name) => ({ src: dirArg(argv, '--src=', SRC, name), testsRepo: dirArg(argv, '--tests-repo=', TESTS_REPO, name) });

function sourceName(file, { testsRepo = TESTS_REPO, src = SRC } = {}, srcPrefix = '') {
  const posix = (p) => p.split(path.sep).join('/');
  const inHarness = path.relative(path.join(testsRepo, HARNESS_DIR), file);
  if (!inHarness.startsWith('..') && !path.isAbsolute(inHarness)) return 'harness/' + posix(inHarness);
  return srcPrefix + posix(path.relative(src, file));
}

module.exports = { coffeeFilesIn, srcFiles, harnessFiles, compiledFiles, sourceRoots, sourceName, SOURCE_RAILS, SRC, TESTS_REPO,
  HARNESS_DIR, byCodePoint };

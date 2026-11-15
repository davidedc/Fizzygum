'use strict';
// cognitive-complexity.js — the vendored Cognitive Complexity analyzer (vendor/coffeescript-cognitive-complexity/,
// SonarSource rule S3776 on the CoffeeScript AST), loaded for the build's gates.
//
// The analyzer walks the AST by node CLASS NAME, so it needs a CoffeeScript whose node classes keep their names. The
// build's own compiler (vendor/coffeescript/, minified) does not; the coffeescript package the toolchain pins does
// (package.json and its lockfile, installed by `npm ci` in Fizzygum/: build_it_please.sh runs its `coffee` to compile
// the boot files). Scores can differ between CoffeeScript versions — a version's AST is its own — so a caller names the
// ONE version its numbers were measured on, and the pinned package is used only at that version: another, or none,
// throws, so a gate says it measured nothing (exit 2) rather than scoring on another AST. The vendored file is loaded
// as published, its one `require("coffeescript")` answered by that package and nothing else resolved from node_modules.
//
//   const { analyzerOn } = require('./lib/cognitive-complexity');
//   const { analyze, coffeescript } = analyzerOn('2.7.0');
//   analyze(source, file) → { functions: [{ name, klass, line, complexity, increments }], … } or { error }
//   coffeescript → { root, version, via } of the package in use

const fs = require('fs');
const path = require('path');
const Module = require('module');

const ANALYZER = path.join(__dirname, '..', '..', 'vendor', 'coffeescript-cognitive-complexity', 'index.js');

// the coffeescript package the toolchain pins, with the version its package.json says (none when it is not installed)
const PINNED = path.join(__dirname, '..', '..', 'node_modules', 'coffeescript');
function pinnedCoffeeScript() {
  const pkgFile = path.join(PINNED, 'package.json');
  const pkg = fs.existsSync(pkgFile) ? JSON.parse(fs.readFileSync(pkgFile, 'utf8')) : {};
  return { root: PINNED, via: 'Fizzygum/node_modules, which package.json pins', name: pkg.name, version: pkg.version };
}

const loaded = new Map();
function analyzerOn(version) {
  if (loaded.has(version)) return loaded.get(version);
  const coffeescript = pinnedCoffeeScript();
  if (coffeescript.name !== 'coffeescript' || coffeescript.version !== version) {
    const seen = coffeescript.version ? `CoffeeScript ${coffeescript.version}` : 'none installed';
    throw new Error(`the pinned CoffeeScript (${coffeescript.via}) is ${seen}, not ${version} — the recorded scores ` +
      `were measured on ${version}: run 'npm ci' in Fizzygum/, or re-measure`);
  }
  const cs = require(coffeescript.root);          // the package itself first: a failure here names it, not the analyzer
  const m = new Module(ANALYZER, module);
  m.filename = ANALYZER;
  m.paths = [];                                   // nothing resolves from node_modules
  const requireAsPublished = m.require.bind(m);
  m.require = (id) => (id === 'coffeescript' ? cs : requireAsPublished(id));
  m._compile(fs.readFileSync(ANALYZER, 'utf8'), ANALYZER);
  const out = { analyze: (source, file) => m.exports.analyzeSource(source, file), coffeescript };
  loaded.set(version, out);
  return out;
}

module.exports = { analyzerOn };

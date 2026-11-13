'use strict';
// cognitive-complexity.js — the vendored Cognitive Complexity analyzer (vendor/coffeescript-cognitive-complexity/,
// SonarSource rule S3776 on the CoffeeScript AST), loaded for the build's gates.
//
// The analyzer walks the AST by node CLASS NAME, so it needs a CoffeeScript whose node classes keep their names. The
// build's own compiler (vendor/coffeescript/, minified) does not; the CoffeeScript the build already requires
// globally does (build_it_please.sh runs its `coffee` to compile the boot files). Scores can differ between
// CoffeeScript versions — a version's AST is its own — so a caller names the ONE version its numbers were measured on,
// and only that version is used: the coffeescript package behind a `coffee` on PATH (resolved through its symlink),
// or in Node's global prefix (`<node>/../lib/node_modules`, where `npm i -g` puts it). Any other is passed over —
// e.g. a project-local `node_modules/.bin/coffee` first on PATH under `npm run` — and with none, loading throws, so a
// gate says it measured nothing (exit 2) rather than scoring on another AST. The vendored file is loaded as
// published, its one `require("coffeescript")` answered by that package and nothing resolved from node_modules.
//
//   const { analyzerOn } = require('./lib/cognitive-complexity');
//   const { analyze, coffeescript } = analyzerOn('2.7.0');
//   analyze(source, file) → { functions: [{ name, klass, line, complexity, increments }], … } or { error }
//   coffeescript → { root, version, via } of the package in use

const fs = require('fs');
const path = require('path');
const Module = require('module');

const ANALYZER = path.join(__dirname, '..', '..', 'vendor', 'coffeescript-cognitive-complexity', 'index.js');

// the coffeescript packages a build could be using: behind each `coffee` on PATH, then Node's global prefix
function candidates() {
  const out = [];
  for (const dir of (process.env.PATH || '').split(path.delimiter)) {
    const bin = path.join(dir || '.', 'coffee');
    if (fs.existsSync(bin)) out.push({ root: path.resolve(path.dirname(fs.realpathSync(bin)), '..'), via: bin });
  }
  out.push({ root: path.resolve(path.dirname(process.execPath), '..', 'lib', 'node_modules', 'coffeescript'), via: 'node\'s global prefix' });
  return out.map((c) => {
    const pkgFile = path.join(c.root, 'package.json');
    const pkg = fs.existsSync(pkgFile) ? JSON.parse(fs.readFileSync(pkgFile, 'utf8')) : {};
    return { ...c, name: pkg.name, version: pkg.version };
  });
}

const loaded = new Map();
function analyzerOn(version) {
  if (loaded.has(version)) return loaded.get(version);
  const found = candidates();
  const coffeescript = found.find((c) => c.name === 'coffeescript' && c.version === version);
  if (!coffeescript) {
    const seen = found.filter((c) => c.name === 'coffeescript').map((c) => `${c.version} (${c.via})`).join(', ') || 'none';
    throw new Error(`no CoffeeScript ${version} found (on PATH or in node's global prefix; seen: ${seen}) — the ` +
      `recorded scores were measured on ${version}: install it globally (npm i -g coffeescript@${version}), or re-measure`);
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

'use strict';
// settling-setters-selftest.js — lib/settling-setters.js on a miniature src written to a temp dir: each family's
// setters are derived from their definer's own bodies, a settle is read from code alone (a settle after a regex
// holding a `#` settles; a `super` named in a string forwards nothing), and an override in the definer's subtree
// that neither settles nor calls super is refused. Run by buildSystem/run-selftests.js on every build.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { settlingSetters } = require('./settling-setters');
const t = require('./selftest-verdict').cases('settling-setters');

const root = fs.mkdtempSync(path.join(os.tmpdir(), 'settling-setters-selftest-'));
let n = 0;
// a fresh src: { 'rel/path.coffee': [lines] }
function srcWith(files) {
  const src = path.join(root, String(n++), 'src');
  for (const [rel, lines] of Object.entries(files)) {
    fs.mkdirSync(path.dirname(path.join(src, rel)), { recursive: true });
    fs.writeFileSync(path.join(src, rel), [...lines, ''].join('\n'));
  }
  return src;
}
// the miniature src alone: a tests repo that does not exist holds no harness (lib/source-files.js harnessFiles)
const NO_TESTS_REPO = path.join(root, 'no-tests-repo');
function outcome(src) {
  try { const s = settlingSetters({ src, testsRepo: NO_TESTS_REPO }); return s.geometry.join(',') + ' | ' + s.text.join(','); } catch (e) { return 'THROWS ' + e.message; }
}
const WIDGET = ['class Widget',
  '  _applyExtent: (e) -> @e = e',
  '  _applyMoveTo: (p) -> @p = p',
  '  setExtent: (e) -> @_settleLayoutsAfter => @_applyExtent e',
  '  moveTo: (p) -> @_settleLayoutsAfter => @_applyMoveTo p'];
const STRING = ['class StringWdgt extends Widget', '  setText: (s) -> @_settleLayoutsAfter => @text = s'];
const base = { 'basic-widgets/Widget.coffee': WIDGET, 'basic-widgets/StringWdgt.coffee': STRING };

let got = outcome(srcWith(base));
t.check(got === 'setExtent,moveTo | setText', 'each family derived from its definer', got);
got = outcome(srcWith({ ...base, 'basic-widgets/Widget.coffee': [...WIDGET.slice(0, 3),
  '  setExtent: (e) ->', '    q = /#x/; @_settleLayoutsAfter => @_applyExtent e', WIDGET[4]] }));
t.check(got === 'setExtent,moveTo | setText', 'a settle after a regex holding a `#` settles', got);
got = outcome(srcWith({ ...base, 'BpTextWdgt.coffee': ['class BpTextWdgt extends StringWdgt', '  setText: (s) -> super s'] }));
t.check(got === 'setExtent,moveTo | setText', 'an override forwarding to super keeps the settle', got);
got = outcome(srcWith({ ...base, 'BpTextWdgt.coffee': ['class BpTextWdgt extends StringWdgt', '  setText: (s) -> log "super"'] }));
t.check(/^THROWS .*BpTextWdgt\.setText \(src\/BpTextWdgt\.coffee:2\) overrides the settling StringWdgt\.setText but neither settles nor calls super/.test(got),
  'an override naming super only in a string is refused', got);
got = outcome(srcWith({ ...base, 'basic-widgets/StringWdgt.coffee': [STRING[0], '  setText: (s) -> @text = s'] }));
t.check(/^THROWS .*the text rule derives no setText/.test(got), 'a base setter that does not settle is refused', got);
fs.rmSync(root, { recursive: true, force: true });
t.done();

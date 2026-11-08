'use strict';
// settle-tiers-selftest.js — lib/settle-tiers.js on a miniature src written to a temp dir: the tiers are read from
// Widget's own definitions, a flush is read from code alone (a flush after a regex holding a `#` is a flush; a flush
// named in a string is none), and the vacuity guard refuses a tier that does not flush and a flush outside a tier.
// Run by buildSystem/run-selftests.js on every build.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { settleTiers } = require('./settle-tiers');
const t = require('./selftest-verdict').cases('settle-tiers');

const root = fs.mkdtempSync(path.join(os.tmpdir(), 'settle-tiers-selftest-'));
let n = 0;
// a fresh src holding only basic-widgets/Widget.coffee, written from `body` (the class body's lines)
function srcWith(...body) {
  const src = path.join(root, String(n++), 'src');
  fs.mkdirSync(path.join(src, 'basic-widgets'), { recursive: true });
  fs.writeFileSync(path.join(src, 'basic-widgets', 'Widget.coffee'), ['class Widget', ...body, ''].join('\n'));
  return src;
}
function outcome(src) {
  try { return settleTiers(src).all.join(','); } catch (e) { return 'THROWS ' + e.message; }
}
const TIERS = [
  '  _settleLayoutsAfter: (f) ->',
  '    f()',
  '    world.recalculateLayouts()',
  '  _settleLayoutsAfterOrJoinEnclosingPass: (f) ->',
  '    world.recalculateLayouts()',
];
const BOTH = '_settleLayoutsAfterOrJoinEnclosingPass,_settleLayoutsAfter';

let got = outcome(srcWith(...TIERS));
t.check(got === BOTH, 'both tiers, longest first', got);
got = outcome(srcWith('  _settleLayoutsAfter: (f) ->', '    q = /#x/; world.recalculateLayouts()', ...TIERS.slice(3)));
t.check(got === BOTH, 'a flush after a regex holding a `#` is a flush', got);
got = outcome(srcWith(...TIERS, '  bpMentionsTheFlush: ->', '    log "world.recalculateLayouts()"'));
t.check(got === BOTH, 'a flush named in a string is no flush', got);
got = outcome(srcWith(...TIERS, '  bpFlushes: ->', '    world.recalculateLayouts()'));
t.check(/^THROWS .*bpFlushes calls recalculateLayouts without the _settleLayoutsAfter… name/.test(got), 'a flush outside a tier name is refused', got);
got = outcome(srcWith('  _settleLayoutsAfter: (f) ->', '    f() # world.recalculateLayouts()', ...TIERS.slice(3)));
t.check(/^THROWS .*_settleLayoutsAfter carries the tier name but does not call recalculateLayouts/.test(got), 'a tier whose flush is only a comment is refused', got);
got = outcome(srcWith(...TIERS.slice(0, 3)));
t.check(/^THROWS .*defines no _settleLayoutsAfterOrJoinEnclosingPass/.test(got), 'a missing role name is refused', got);
fs.rmSync(root, { recursive: true, force: true });
t.done();

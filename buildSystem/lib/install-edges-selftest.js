'use strict';
// install-edges-selftest.js — lib/install-edges.js on a miniature src written to a temp dir: an edge is read from
// boot's code alone (one after a string holding a `#` is an edge; one named in a string is none), a support class's
// keys are read past a heregex holding `'''`, its statics list is read to its closing bracket (not to a `]` in a
// comment), and a statics list that disagrees with the class's own statics is refused. Run by
// buildSystem/run-selftests.js on every build.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { installEdges } = require('./install-edges');
const t = require('./selftest-verdict').cases('install-edges');

const root = fs.mkdtempSync(path.join(os.tmpdir(), 'install-edges-selftest-'));
let n = 0;
// a fresh src: boot/globalFunctions.coffee from `boot` (startWorld's body lines), BpSupport.coffee from `support`
function srcWith(boot, support) {
  const src = path.join(root, String(n++), 'src');
  fs.mkdirSync(path.join(src, 'boot'), { recursive: true });
  fs.writeFileSync(path.join(src, 'boot', 'globalFunctions.coffee'), ['startWorld = ->', ...boot, ''].join('\n'));
  fs.writeFileSync(path.join(src, 'BpSupport.coffee'), ['class BpSupport', ...support, ''].join('\n'));
  return src;
}
// the miniature src alone: a tests repo that does not exist holds no harness (lib/source-files.js harnessFiles)
const NO_TESTS_REPO = path.join(root, 'no-tests-repo');
function outcome(src) {
  try {
    return installEdges({ src, testsRepo: NO_TESTS_REPO }).map((e) => `${e.support}->${e.target}@${e.bootLine}:${e.members.map((m) => (m.isStatic ? '@' : '') + m.name).join(',')}`).join(' ');
  } catch (e) { return 'THROWS ' + e.message; }
}
const EDGE = '  BpSupport.installOnto Widget if BpSupport?';
const COPIES = ['  @installOnto: (target) ->',
  '    for own name, member of @prototype when name isnt "constructor"',
  '      target.prototype[name] = member',
  '    target[name] = @[name] for name in @staticMembersToInstall'];
const STATICS = ['  @staticMembersToInstall: ["bpStatic"]', '  @bpStatic: 1'];

let got = outcome(srcWith([EDGE], [...COPIES, ...STATICS, '  bpMember: -> 1']));
t.check(got === 'BpSupport->Widget@2:bpMember,@bpStatic', 'an edge, its prototype members and its listed statics', got);
got = outcome(srcWith(['  log "#"; ' + EDGE.trim()], [...COPIES, '  bpMember: -> 1']));
t.check(got === 'BpSupport->Widget@2:bpMember', 'an edge after a string holding a `#` is an edge', got);
got = outcome(srcWith(['  log "BpSupport.installOnto Widget"', EDGE], [...COPIES, '  bpMember: -> 1']));
t.check(got === 'BpSupport->Widget@3:bpMember', 'an edge named in a string is no edge', got);
got = outcome(srcWith([EDGE], [...COPIES, "  bpPattern: ///'''///", '  bpMember: -> 1']));
t.check(got === 'BpSupport->Widget@2:bpPattern,bpMember', "a key after a heregex holding ''' is a key", got);
got = outcome(srcWith([EDGE], [...COPIES, '  @staticMembersToInstall: [ # the statics [copied whole]', '    "bpStatic"', '  ]', '  @bpStatic: 1']));
t.check(got === 'BpSupport->Widget@2:@bpStatic', 'a statics list is read to its bracket, not to a `]` in a comment', got);
got = outcome(srcWith([EDGE], [...COPIES, ...STATICS, '  @bpUnlisted: 2']));
t.check(/^THROWS [\s\S]*\n  UNLISTED_STATIC BpSupport\.bpUnlisted — /.test(got), 'a static the list leaves out is refused', got);
got = outcome(srcWith([EDGE], ['  @installOnto: (target) -> target.bp = 1', '  bpMember: -> 1']));
t.check(/^THROWS BpSupport\.installOnto copies neither its prototype nor @staticMembersToInstall/.test(got), 'an installOnto of another shape is refused', got);
fs.rmSync(root, { recursive: true, force: true });
t.done();

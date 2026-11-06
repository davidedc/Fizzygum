'use strict';
// check-unresolved-sends-selftest.js — check-unresolved-sends.js's pure parts on in-memory fixtures: the masker
// (strings and comments cut, interpolation kept), every definition form the implementor harvest needs, the call
// harvest, and the literal receiver a keyed BUILTINS entry is matched against. A lint that cannot fail is
// worthless. Run by buildSystem/run-selftests.js on every build.

const fs = require('fs');
const path = require('path');
const { stripLine, harvestDefs, harvestCalls } = require('./check-unresolved-sends');
const t = require('./lib/selftest-verdict').cases('unresolved-sends');

// a case passes when what it got equals what it wants, compared as JSON
const check = (label, got, want) => {
  const pass = JSON.stringify(got) === JSON.stringify(want);
  t.check(pass, `${label} -> ${JSON.stringify(got)}`, `expected ${JSON.stringify(want)}`);
};
// masker: strings/comments masked, interpolation kept
const code1 = (l) => stripLine(l, null).code;
check('call in a comment is masked',        /@foo\(/.test(code1('x = 1 # @foo()')), false);
check('call in a string is masked',         /@foo\(/.test(code1('x = "@foo()"')), false);
check("call in a '-string is masked",       /@foo\(/.test(code1("x = '@foo()'")), false);
check('call in interpolation is KEPT',      /@foo\(/.test(code1('x = "a#{@foo()}b"')), true);
check('plain call survives',                /@foo\(/.test(code1('@foo()')), true);
check('heredoc opens multi-line state',     stripLine('x = """', null).state, '"""');
check('heredoc body masked, interp kept',   stripLine('@a() #{@b()}', '"""').code.includes('@b()'), true);
check('heredoc body code masked',           stripLine('@a() #{@b()}', '"""').code.includes('@a()'), false);
// def harvest: every form the probe proved necessary
const defsOf = (src) => {
  const f = path.join(require('os').tmpdir(), `__ust_${process.pid}.coffee`);
  fs.writeFileSync(f, src); const d = harvestDefs([f]); fs.unlinkSync(f); return [...d].sort();
};
check('2-space class method',  defsOf('  myMethod: (a) ->\n').includes('myMethod'), true);
check('prototype extension',   defsOf('Number::toRadians = ->\n').includes('toRadians'), true);
check('static fn',             defsOf('Math.getRandomInt = (min, max) ->\n').includes('getRandomInt'), true);
check('local-proto expando',   defsOf('  swContextProto.useLogicalPixels = ->\n').includes('useLogicalPixels'), true);
check('bare local fn',         defsOf('helper = ->\n').includes('helper'), true);
check('plain property key',    defsOf('  bounds: nil\n').includes('bounds'), true);
check('@-assignment key',      defsOf('    @myField = 3\n').includes('myField'), true);
// the DEF forms are line-ANCHORED, so a def inside a mid-line string is not harvested…
check('mid-line string def not harvested',   defsOf('x = "  fake: ->"\n').includes('fake'), false);
// …but a heredoc BODY line is (the naive strip keeps string content). Over-approximating like this
// is HARMLESS by construction: an extra implementor can only ever SUPPRESS a flag, never raise one.
check('heredoc-body def over-approximated', defsOf('code = """\n  fake: ->\n"""\n').includes('fake'), true);
// call harvest: capitals skipped
const callsOf = (src) => {
  const f = path.join(require('os').tmpdir(), `__ust_${process.pid}.coffee`);
  fs.writeFileSync(f, src); const c = harvestCalls([f]).map((s) => s.name); fs.unlinkSync(f); return c;
};
check('member + self calls harvested', callsOf('@aa()\nx.bb()\n'), ['aa', 'bb']);
check('Capitalised name skipped',      callsOf('x.Foo()\n'), []);
// the receiver a keyed BUILTINS entry is matched against: a bare identifier right before the dot only
const recvsOf = (src) => {
  const f = path.join(require('os').tmpdir(), `__ust_${process.pid}.coffee`);
  fs.writeFileSync(f, src); const c = harvestCalls([f]).map((s) => s.recv || '-'); fs.unlinkSync(f); return c;
};
check('literal global receiver read',      recvsOf('x = Math.round(y)\nJSON.parse(s)\nf(Math.max(1, 2))\n'), ['Math', 'JSON', 'Math']);
check('a spaced dot is no receiver',       recvsOf('y = Math .floor(z)\n'), ['-']);
check('an interpolation is no receiver',   recvsOf('x = "a#{Math}".round(y)\ny = "#{q} #{document}".createElement(z)\n'), ['-', '-']);
check('an expression is no receiver',      recvsOf('@bounds.round()\na.Math.round()\n(x).round()\nlist[0].round()\n'), ['-', '-', '-', '-']);
check('@-self call has no receiver',       recvsOf('@round()\n'), ['-']);
check('a string is no receiver',           recvsOf('"Math".round()\n'), ['-']);

t.done();

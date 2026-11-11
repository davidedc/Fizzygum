'use strict';
// check-unresolved-sends-selftest.js — check-unresolved-sends.js's pure parts on in-memory fixtures: every definition
// form the implementor harvest needs, the call harvest (a call in a string or a comment is none, one in an
// interpolation is, and so is one after a regex holding `#` or a heregex holding `'''`), and the literal receiver a
// keyed BUILTINS entry is matched against. A lint that cannot fail is worthless. Run by buildSystem/run-selftests.js
// on every build.

const fs = require('fs');
const path = require('path');
const { harvestDefs, harvestCalls } = require('./check-unresolved-sends');
const t = require('./lib/selftest-verdict').cases('unresolved-sends');

// a case passes when what it got equals what it wants, compared as JSON
const check = (label, got, want) => {
  const pass = JSON.stringify(got) === JSON.stringify(want);
  t.check(pass, `${label} -> ${JSON.stringify(got)}`, `expected ${JSON.stringify(want)}`);
};
// def harvest: every CALLABLE form, and none that is not (lib/name-definitions.js's header)
const defsOf = (src) => {
  const f = path.join(require('os').tmpdir(), `__ust_${process.pid}.coffee`);
  fs.writeFileSync(f, src); const d = harvestDefs([f]); fs.unlinkSync(f); return [...d].sort();
};
check('2-space class method',  defsOf('  myMethod: (a) ->\n').includes('myMethod'), true);
check('prototype extension',   defsOf('Number::toRadians = ->\n').includes('toRadians'), true);
check('static fn',             defsOf('Math.getRandomInt = (min, max) ->\n').includes('getRandomInt'), true);
check('local-proto expando',   defsOf('  swContextProto.useLogicalPixels = ->\n').includes('useLogicalPixels'), true);
check('top-level fn',          defsOf('helper = ->\n').includes('helper'), true);
check('class-side method',     defsOf('  @make: (a) ->\n').includes('make'), true);
check('one-line class-side',   defsOf('  @style: -> theme.x\n').includes('style'), true);
check('paren-default header',  defsOf('  click: (w = @topWdgt()) ->\n').includes('click'), true);
check('wrapped signature',     defsOf('  long: (\n    a\n  ) ->\n').includes('long'), true);
check('continued header',      defsOf('  notify: \\\n    (a) ->\n').includes('notify'), true);
check('a # in a default string', defsOf('  label: (s = "#") ->\n').includes('label'), true);
// a value that is not a function defines nothing a `[@.]name(` send can reach: the masks the catch-all had
check('plain property key is data',  defsOf('  bounds: undefined\n').includes('bounds'), false);
check('@-assignment is data',        defsOf('    @myField = 3\n').includes('myField'), false);
check('indented local fn is local',  defsOf('  draw: ->\n    width = (i) -> i\n').includes('width'), false);
// the DEF forms are line-ANCHORED, so a def inside a mid-line string is not harvested…
check('mid-line string def not harvested',   defsOf('x = "  fake: ->"\n').includes('fake'), false);
// …but a heredoc BODY line is (definitions are read off code with its literals kept). Over-approximating like this
// is HARMLESS by construction: an extra implementor can only ever SUPPRESS a flag, never raise one.
check('heredoc-body def over-approximated', defsOf('code = """\n  fake: ->\n"""\n').includes('fake'), true);
// call harvest: capitals skipped
const callsOf = (src) => {
  const f = path.join(require('os').tmpdir(), `__ust_${process.pid}.coffee`);
  fs.writeFileSync(f, src); const c = harvestCalls([f]).map((s) => s.name); fs.unlinkSync(f); return c;
};
check('member + self calls harvested', callsOf('@aa()\nx.bb()\n'), ['aa', 'bb']);
check('Capitalised name skipped',      callsOf('x.Foo()\n'), []);
check('a call in a comment is none',   callsOf('x = 1 # @foo()\n'), []);
check('a call in a string is none',    callsOf('x = "@foo()"\ny = \'@bar()\'\n'), []);
check('a call in an interpolation is one', callsOf('x = "a#{@foo()}b"\n'), ['foo']);
check('a heredoc body is text, its interpolation code', callsOf('x = """\n  @a() #{@b()}\n  """\n'), ['b']);
check('a call after a regex holding # is one',   callsOf('r = /#x/; @after()\n'), ['after']);
check("a call after a heregex holding ''' is one", callsOf("r = ///'''///\n@after()\n"), ['after']);
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

// ---- the REAL gate on a planted src copy ---------------------------------------------------------------------------
// The cases above judge the harvests in memory; here the gate itself — the walk, the harness and macro sources, both
// exemption tables, the exit — runs on a src copy and a copy of the tests repo's code (lib/planted-src.js). THE MASK
// THIS HARVEST CLOSED: every callable definition of a name that still has a DATA key elsewhere is removed from the copy,
// and a send of it must FAIL — the catch-all definition form kept such a send resolved (lib/name-definitions.js). The
// definers are found by the harvest itself, so the plant follows the tree. Run 2 takes away what one entry of each
// table excuses. Run 3 plants a send nobody defines in a harness file, which fails named harness/<path>.
const { proveGate, SRC } = require('./lib/planted-src');
const { definedName } = require('./lib/name-definitions');
const { coffeeMask } = require('./lib/coffee-mask');
const { compiledFiles } = require('./lib/source-files');
const MASKED = 'close';   // defined by a method, and still a data key (FrameWdgt's theme table)
// the compiled sources the gate reads (src/ and the harness); the definers src-relative — the plant edits only the
// src copy, so a definer outside it (a `../` path) would keep the send resolved
const COMPILED = compiledFiles({ src: SRC });
const definers = [];
for (const f of COMPILED) {
  if (coffeeMask(fs.readFileSync(f, 'utf8'), f).some((l) => definedName(l.code) === MASKED)) definers.push(path.relative(SRC, f));
}
const dataKeyKept = COMPILED.some((f) => new RegExp(`^\\s*${MASKED}\\s*:\\s*[^-=(\\s]`, 'm').test(fs.readFileSync(f, 'utf8')));
t.check(definers.length > 0 && definers.every((f) => !f.startsWith('..')) && dataKeyKept,
  `the masked name '${MASKED}' has a callable definer, each in src (${definers.join(', ')}), and a data key that stays`);
proveGate({
  name: 'unresolved-sends',
  cases: t,
  gate: path.join(__dirname, 'check-unresolved-sends.js'),
  testsRepo: true,
  pass: /^\[unresolved-sends\] OK — /m,
  control: {
    plants: {
      'BiteProofSendsOk.coffee': ['class BiteProofSendsOk', '  bp: (zip) ->', '    # @biteProofInAComment()', '    s = "@biteProofInAString()"',
        '    zip.generateAsync()', '    [1].push(2)', '    Math.round(1.5)', '    x.CapitalisedName()', ''].join('\n'),
    },
  },
  runs: [{
    label: 'a masked name with its methods gone, a send nobody defines, two tables in the wrong form',
    edits: definers.map((f) => [f, new RegExp(`^(\\s*@?)${MASKED}(\\s*:)`, 'gm'), `$1${MASKED}BiteProofRenamed$2`]),
    plants: {
      'BiteProofSends.coffee': ['class BiteProofSends', '  bpMasked: (w) ->', `    w.${MASKED}()`, '  bpNobody: ->', '    @biteProofNoSuchMethod()',
        '  digest: -> 1', '  isView: -> 1', ''].join('\n'),
      'performance.coffee': 'class performance\n',
      // a verb's send (a Macro.fromString literal of src), which the file's own reading sees only as a string
      'BiteProofSendsVerbs.coffee': ['class BiteProofSendsVerbs', '  standard: ->', '    Macro.fromString """', '      bp_Macro = (w) ->',
        '        w.biteProofVerbSend()', '    """', ''].join('\n'),
    },
    expect: {
      UNRESOLVED_SEND: new RegExp(`^  src/BiteProofSends\\.coffee:3: \\.${MASKED}\\( — no definition found in src\\+harness$`, 'm'),
      STALE_ALLOWLIST_ENTRY: /^  STALE_ALLOWLIST_ENTRY digest — it resolves: a definition of it is in src\+harness$/m,
      BUILTINS_NOT_KEYED: /^  BUILTINS_NOT_KEYED isView — Fizzygum defines isView, and every `\.isView\(` call sends it to a platform global \(ArrayBuffer\)/m,
      PLATFORM_GLOBALS_NAMES_FIZZYGUM: /^  PLATFORM_GLOBALS_NAMES_FIZZYGUM performance — performance is a Fizzygum class/m,
    },
    lines: [/^  src\/BiteProofSends\.coffee:5: @biteProofNoSuchMethod\( — no definition found/m,
            /^  src\/BiteProofSendsVerbs\.coffee:5: \.biteProofVerbSend\( — no definition found/m],
    absent: [/BiteProofSendsOk/],
  }, {
    label: 'what one entry of each table excuses, taken away',
    edits: [['icons/CurledArrowsSquareIconAppearance.coffee', /Math\.asin\(/, 'Math.sin('],             // the one sender of asin
            ['serialization/NativeValueKinds.coffee', /^  @isArray(\s*:)/m, '  @isArrayBiteProofRenamed$1'],   // isArray's one definer
            ['serialization/NativeValueKinds.coffee', /ArrayBuffer\.isView\(/, 'bpBuffer.isView(']],     // ArrayBuffer's one BUILTINS send
    expect: {
      STALE_BUILTIN: /^  STALE_ALLOWLIST_ENTRY BUILTINS asin — no `\[@\.\]asin\(` call in src, the harness or a macro sends it/m,
      BUILTINS_KEYED_NOTHING_TO_UNMASK: /^  BUILTINS_KEYED_NOTHING_TO_UNMASK Array\.isArray — no definition of isArray is in src\+harness: list it bare$/m,
      STALE_PLATFORM_GLOBAL: /^  STALE_ALLOWLIST_ENTRY PLATFORM_GLOBALS ArrayBuffer — no BUILTINS call/m,
    },
  }, {
    label: 'a harness file',
    plants: { 'harness/BiteProofHarnessSends.coffee': ['class BiteProofHarnessSends', '  bpNobody: ->', '    @biteProofHarnessNoSuchMethod()', ''].join('\n') },
    expect: { UNRESOLVED_SEND: /^  harness\/BiteProofHarnessSends\.coffee:3: @biteProofHarnessNoSuchMethod\( — no definition found in src\+harness$/m },
  }],
});

t.done();

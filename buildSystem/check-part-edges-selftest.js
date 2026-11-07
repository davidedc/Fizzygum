'use strict';
// check-part-edges-selftest.js — check-part-edges.js's clauses on in-memory fixtures, every one both ways: which
// installed members are a part's own, the member guard (reference, by-name dispatch, super), and the unused-
// `requires` rule. Those are unit tests of the engine; the gate's rules are proven to BITE at the end, by running the
// REAL gate (build.py's listing, parts.json, the class model, the boot install edges) on a planted copy of src/ and a
// planted parts.json (lib/planted-src.js). Run by buildSystem/run-selftests.js on every build.

const { soleProviders, memberReaches, superReaches, unusedRequires } = require('./check-part-edges');
const { codePartOf, guardedPartsPerLine } = require('./lib/part-edge-scan');
const t = require('./lib/selftest-verdict').cases('part-edges');

// a case passes when what it got equals what it wants, compared as JSON
const check = (label, got, want) => {
  const pass = JSON.stringify(got) === JSON.stringify(want);
  t.check(pass, `${label} -> ${JSON.stringify(got)}`, `expected ${JSON.stringify(want)}`);
};
const fixtureParts = { core: { dirs: [] }, harness: { dirs: [] }, authoring: { dirs: [] } };
const classOwner = new Map([['WidgetTestSupport', 'harness']]);
const sole = new Map([['serialiseToMemory', 'harness'], ['_sizeCanvasToTestScreenResolution', 'harness']]);
const never = () => false;
const reach = (src, owner = 'core', isSatisfied = never) => {
  const lines = src.split('\n');
  const guards = guardedPartsPerLine(lines, classOwner, fixtureParts, sole);
  return memberReaches(lines, guards, sole, owner, isSatisfied).map(v => `${v.clause}:${v.line}:${v.name}`);
};

// which installed members are the part's own: the support class defining them does not withdraw
// them, nor does another file of the same part; a definition in any OTHER part does, and so does a
// second installing part; a send is no definition
const owned = soleProviders(
  new Map([['serialiseToMemory', new Set(['harness'])], ['makeSpacersOpaque', new Set(['harness'])],
           ['installedTwice', new Set(['harness', 'tools'])]]),
  [{ part: 'harness',   lines: ['class WidgetTestSupport', '  serialiseToMemory: ->', '  makeSpacersOpaque: ->', '  installedTwice: ->'] },
   { part: 'harness',   lines: ['class MacroToolkit', '  serialiseToMemory: -> 1'] },
   { part: 'tools',     lines: ['class ToolsSupport', '  installedTwice: ->'] },
   { part: 'authoring', lines: ['class LayoutSpacerWdgt extends Widget', '  makeSpacersOpaque: ->', '    @x = 1'] },
   { part: 'core',      lines: ['class Caller', '  run: ->', '    x.serialiseToMemory()'] }]);
check('owned: only the part defines it, however often',  owned.get('serialiseToMemory'), 'harness');
check('owned: a definition in another part withdraws it', owned.has('makeSpacersOpaque'), false);
check('owned: two installing parts withdraw it',          owned.has('installedTwice'), false);
check('owned: exactly one member is a part\'s own',       [...owned.keys()], ['serialiseToMemory']);

// clause (a)
check('(a) unguarded call',                reach('    @_sizeCanvasToTestScreenResolution()'), ['a:1:_sizeCanvasToTestScreenResolution']);
check('(a) unguarded read',                reach('    f = world.serialiseToMemory'), ['a:1:serialiseToMemory']);
check('(a) a soak call is a guard',        reach('    @_sizeCanvasToTestScreenResolution?()'), []);
check('(a) a member test opens a scope',   reach('    if @_sizeCanvasToTestScreenResolution?\n      @serialiseToMemory()'), []);
check('(a) ...which closes at its indent', reach('    if @_sizeCanvasToTestScreenResolution?\n      x = 1\n    @serialiseToMemory()'), ['a:3:serialiseToMemory']);
check('(a) a member bail-out',             reach('  m: ->\n    return unless world.serialiseToMemory?\n    world.serialiseToMemory()'), []);
check('(a) a class guard covers it',       reach('    if WidgetTestSupport?\n      x.serialiseToMemory()'), []);
check('(a) defined outside the part',      reach('    x.sharedName()'), []);
check('(a) in a comment',                  reach('    # @serialiseToMemory()'), []);
check('(a) in the installing part',        reach('    @serialiseToMemory()', 'harness'), []);
check('(a) a requires-satisfied file',     reach('    @serialiseToMemory()', 'authoring', (p) => p === 'harness'), []);

// clause (b)
check('(b) a row dispatching by name',     reach('    menu.addMenuItem "Serialise", w, "serialiseToMemory"'), ['b:1:serialiseToMemory']);
check('(b) the same row, guarded',         reach('    if WidgetTestSupport?\n      menu.addMenuItem "Serialise", w, "serialiseToMemory"'), []);
check('(b) a member defined elsewhere',    reach('    menu.addMenuItem "Share", w, "sharedName"'), []);
check('(b) a string that only contains it', reach('    menu.addMenuItem "serialiseToMemory now", w, "sharedName"'), []);
check('(b) in a comment',                  reach('    # menu.addMenuItem "x", w, "serialiseToMemory"'), []);

// clause (c): Widget is given makeSpacersOpaque by the harness; the class model is built by hand in
// the census's shape. Leaf/Leaf2/… sit under Mid (core); MidDef (core) defines the member itself.
const sources = {
  Widget:  { parent: null,     part: 'core',      src: 'class Widget\n  other: ->\n    1' },
  Mid:     { parent: 'Widget', part: 'core',      src: 'class Mid extends Widget\n  other: ->\n    super' },
  MidDef:  { parent: 'Widget', part: 'core',      src: 'class MidDef extends Widget\n  makeSpacersOpaque: ->\n    2' },
  Leaf:    { parent: 'Mid',    part: 'authoring', src: 'class Leaf extends Mid\n  makeSpacersOpaque: ->\n    @x = 1\n    super' },
  Leaf2:   { parent: 'Mid',    part: 'authoring', src: 'class Leaf2 extends Mid\n  makeSpacersOpaque: ->\n    @x = 1' },
  Leaf3:   { parent: 'MidDef', part: 'authoring', src: 'class Leaf3 extends MidDef\n  makeSpacersOpaque: ->\n    super' },
  Leaf4:   { parent: 'Mid',    part: 'authoring', src: 'class Leaf4 extends Mid\n  makeSpacersOpaque: ->\n    super.other()' },
  Leaf5:   { parent: 'Mid',    part: 'authoring', src: 'class Leaf5 extends Mid\n  makeSpacersOpaque: ->\n    super if WidgetTestSupport?' },
  Leaf6:   { parent: 'Mid',    part: 'authoring', src: 'class Leaf6 extends Mid\n  makeSpacersOpaque: ->\n    if @serialiseToMemory?\n      super' },
  // the member under test is NOT the part's alone (Leaf defines it), so testing it proves nothing
  Leaf7:   { parent: 'Mid',    part: 'authoring', src: 'class Leaf7 extends Mid\n  makeSpacersOpaque: ->\n    if @makeSpacersOpaque?\n      super' },
};
const classInfo = new Map();
const files = new Map();
for (const [name, s] of Object.entries(sources)) {
  const lines = s.src.split('\n');
  const methods = new Map();
  let cur;
  lines.forEach((l, i) => {
    const h = /^  ([A-Za-z_]\w*): ->/.exec(l);
    if (h) { cur = { bodyLines: [] }; methods.set(h[1], cur); return; }
    if (cur) cur.bodyLines.push({ n: i + 1, code: codePartOf(l) });
  });
  classInfo.set(name, { name, parent: s.parent, mixins: [], methods });
  files.set(name, { rel: name + '.coffee', owner: s.part, isSatisfied: never,
                    guards: guardedPartsPerLine(lines, classOwner, fixtureParts, sole) });
}
const chainOf = (cls) => { const out = []; for (let c = classInfo.get(cls); c; c = classInfo.get(c.parent)) out.push(c); return out; };
const supers = superReaches({ classInfo, chainOf }, new Map([['Widget', new Map([['makeSpacersOpaque', 'harness']])]]),
                            (n) => sources[n].part, (n) => files.get(n)).map(v => `${v.cls}:${v.line}`);
check('(c) super into a member only the part installs',  supers.includes('Leaf:4'), true);
check('(c) no super, no reach',                          supers.some(s => s.startsWith('Leaf2:')), false);
check('(c) a definition outside the part answers it',    supers.some(s => s.startsWith('Leaf3:')), false);
check('(c) super.other() reaches another member',        supers.some(s => s.startsWith('Leaf4:')), false);
check('(c) a class guard covers it',                     supers.some(s => s.startsWith('Leaf5:')), false);
check('(c) a test on a member only the part has covers it', supers.some(s => s.startsWith('Leaf6:')), false);
check('(c) a test on a member others define does not',  supers.includes('Leaf7:4'), true);
check('(c) exactly those two reaches in the fixture',    supers, ['Leaf:4', 'Leaf7:4']);

// unused requires: an entry is backed only by a class of that part named in code
const unused = unusedRequires(
  { '//': 'a comment key is no part', door: { requires: ['kit', 'art'] }, kit: {}, art: {},
    empty: { requires: ['kit'] }, plain: {} },
  new Map([['door', new Set(['kit', 'other'])]])).map(v => `${v.part}->${v.requires}`);
check('requires: a named part backs it, an unnamed one does not', unused.includes('door->kit'), false);
check('requires: an entry nothing names is reported',              unused.includes('door->art'), true);
check('requires: a part with no scanned code backs nothing',       unused.includes('empty->kit'), true);
check('requires: exactly those two in the fixture',                unused, ['door->art', 'empty->kit']);


// ---- the REAL gate on a planted src copy (core = the src root: every plant is core code) ------------------------
// Each member clause uses a DIFFERENT installed member: a member defined anywhere outside its installing part stops
// being that part's symbol, and the (c) plant defines the member it overrides.
const fs = require('fs');
const os = require('os');
const path = require('path');
const { proveGate } = require('./lib/planted-src');
const cls = (name, parent, ...body) => [`class ${name} extends ${parent}`, ...body, ''].join('\n');
const partsDir = fs.mkdtempSync(path.join(os.tmpdir(), 'check-part-edges-selftest-'));
process.on('exit', () => fs.rmSync(partsDir, { recursive: true, force: true }));
const plantedParts = JSON.parse(fs.readFileSync(path.join(__dirname, 'parts.json'), 'utf8'));
plantedParts.parts.maps.requires = [...(plantedParts.parts.maps.requires || []), 'plots'];   // maps never names a plots class
fs.writeFileSync(path.join(partsDir, 'parts.json'), JSON.stringify(plantedParts, null, 2));
proveGate({
  name: 'part-edges',
  cases: t,
  gate: path.join(__dirname, 'check-part-edges.js'),
  pass: /^\[part-edges\] OK -- every core reference into a part, to a class or to a member it installs, is guarded\.$/m,
  control: {
    plants: {
      'BiteProofPartGuardsWdgt.coffee': cls('BiteProofPartGuardsWdgt', 'Widget',
        '  bpNamesOnly: ->', '    # HhmmssLabelWdgt in a comment', '    s = "HhmmssLabelWdgt in a string"',
        '  bpSameLine: ->', '    @bpA = new HhmmssLabelWdgt() if HhmmssLabelWdgt?',
        '  bpBlock: ->', '    if HhmmssLabelWdgt?', '      @bpB = new HhmmssLabelWdgt()',
        '  bpEarly: ->', '    return unless HhmmssLabelWdgt?', '    @bpC = new HhmmssLabelWdgt()',
        '  bpMembers: (w) ->', '    @serialiseToMemory?()', '    if w.deserialiseFromMemoryAndAttachToWorld?', '      w.deserialiseFromMemoryAndAttachToWorld()'),
    },
  },
  runs: [{
    label: 'an unguarded class, an inheritance, a member three ways, a requires entry nothing uses',
    args: ['--parts=' + path.join(partsDir, 'parts.json')],   // a planted parts.json: maps requires plots
    plants: {
      'BiteProofPartRefWdgt.coffee': cls('BiteProofPartRefWdgt', 'Widget', '  bpMake: ->', '    @bpIcon = new SimpleUSAMapIconAppearance @', '    @bpLabel = new HhmmssLabelWdgt()'),
      'BiteProofPartInheritWdgt.coffee': cls('BiteProofPartInheritWdgt', 'SimpleUSAMapIconAppearance'),
      'BiteProofPartMemberWdgt.coffee': cls('BiteProofPartMemberWdgt', 'Widget', '  bpReach: (menu, w) ->', '    @serialiseToMemory()',
        '    menu.addMenuItem "bp", w, "deserialiseFromMemoryAndAttachToWorld"'),
      'BiteProofPartSuperWdgt.coffee': cls('BiteProofPartSuperWdgt', 'Widget', '  fullRenderCanvasAsItAppearsOnScreen: ->', '    super()'),
    },
    expect: {
      UNGUARDED_CLASS_REF: /^  src\/BiteProofPartRefWdgt\.coffee:3  \S+ -> SimpleUSAMapIconAppearance \(part 'maps', LAZY\)$/m,
      INHERITS_FROM_PART: /^  src\/BiteProofPartInheritWdgt\.coffee:1  \S+ -> SimpleUSAMapIconAppearance \(part 'maps'\)$/m,
      MEMBER_REFERENCE: /^  src\/BiteProofPartMemberWdgt\.coffee:3  \S+ -> \.serialiseToMemory \(installed by part '\w+'; \(a\) a reference\)$/m,
      MEMBER_DISPATCHED_BY_NAME: /^  src\/BiteProofPartMemberWdgt\.coffee:4  \S+ -> "deserialiseFromMemoryAndAttachToWorld" \(installed by part '\w+'; \(b\) dispatched by name\)$/m,
      UNUSED_REQUIRES: /^  maps requires 'plots'$/m,
      MEMBER_SUPER: /^  src\/BiteProofPartSuperWdgt\.coffee:\d+  \S+ -> BiteProofPartSuperWdgt\.fullRenderCanvasAsItAppearsOnScreen -> super \(installed by part '\w+'; \(c\) a super into it\)$/m,
    },
    lines: [/^  src\/BiteProofPartRefWdgt\.coffee:4  \S+ -> HhmmssLabelWdgt \(part 'video-player'\)$/m],
    absent: [/BiteProofPartGuardsWdgt/],
  }],
});

t.done();

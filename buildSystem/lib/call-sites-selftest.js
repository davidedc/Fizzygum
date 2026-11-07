'use strict';
// call-sites-selftest.js — lib/call-sites.js's readings, one case each, on a throwaway fixture: a src tree (the real
// meta/Class.coffee + meta/Mixin.coffee beside a few fixture classes) and a tests repo (a macro, a broken macro, a
// script). Each case names the reading it holds — the three 2.0.3 call shapes, the implicit object, the nested
// paren-less call, the three super forms, a string that is no call, a lifted heredoc on its file line (and an
// interpolated one refused), the trailing absence, the this-arg exclusion, the JS forms (ES2022 included), the
// identities — a constructor-less subclass, a top-level function called from other files, classes a script or a
// macro defines, `new @constructor` — the harness read, and the callers test's value/hole pair.
// Run by buildSystem/run-selftests.js on every build.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { callSites, callersTest } = require('./call-sites');
const t = require('./selftest-verdict').cases('call-sites');

const REAL_SRC = path.resolve(__dirname, '..', '..', 'src');
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'call-sites-'));
const src = path.join(root, 'src');
const repo = path.join(root, 'tests-repo');
const put = (p, text) => { fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, text); };
for (const m of ['Class.coffee', 'Mixin.coffee']) put(path.join(src, 'meta', m), fs.readFileSync(path.join(REAL_SRC, 'meta', m), 'utf8'));
put(path.join(src, 'BpBase.coffee'), [
  'class BpBase', '  constructor: (a, b, c) ->', '    @x = a', '  bpCallee: (a, b, c) -> a', '  bpOpts: (a, opts) -> a', ''].join('\n'));
put(path.join(src, 'BpChild.coffee'), [
  'class BpChild extends BpBase',
  '  constructor: (a, b) ->',
  '    super a, b',                                   // 3
  '  other: ->',
  '    super()',                                      // 5
  '  third: ->',
  '    super',                                        // 7
  '  callers: ->',
  '    @bpCallee 1, undefined, 3',                    // 9: a HOLE — line 11 and the macro's `@bpCallee 8` reach 1
  '    @bpCallee 4, 5, 6',
  '    @bpCallee 7, undefined',                       // 11: trailing only, reach 1 — and so a WITNESS
  '    @bpOpts 1, face: 2, tip: 3',                   // 12: an implicit object is ONE argument
  '    @bpNest "x", undefined, bpG new BpBase 1, 2',  // 13: the nested paren-less call is ONE argument
  '    s = "use undefined, then 1"',                  // 14: a string, no call
  '    fn.call undefined, 1',                         // 15: a this-arg
  '    JSON.stringify s, undefined, 2',               // 16: foreign
  '    new BpBase',                                   // 17: Op('new', X)
  '    y = new BpBase(1).x',                          // 18: Op('new') over a property chain
  '    new BpBase 1, 2',                              // 19: Call isNew
  '    visit = (n, m) -> n',
  '    visit undefined, 1',                           // 21: a member-local function
  '    new (classNamed "BpBase")',                    // 22: dynamic
  '    new BpLeaf 1, 2',                              // 23: a constructor-less subclass: BpBase's constructor
  '    bpGlobal 1',                                   // 24: a boot global, called from another file
  '    new @constructor 1, 2',                        // 25: names its own class
  '', ''].join('\n'));
put(path.join(src, 'BpLeaf.coffee'), ['class BpLeaf extends BpBase', '  leafy: -> 1', ''].join('\n'));
put(path.join(src, 'boot', 'bp-globals.coffee'), ['bpGlobal = (a, b, c) -> a', 'bpGlobal 1, undefined, 3', ''].join('\n'));
put(path.join(src, 'BpInterpolated.coffee'), [
  'class BpInterpolated', '  subs: ->', '    Macro.fromString """', '      i_Macro = ->', '        @bpHeredoc #{2}', '    """', ''].join('\n'));
put(path.join(src, 'BpToolkit.coffee'), [
  'class BpToolkit', '  subs: ->', '    Macro.fromString """', '      hd_Macro = ->', '        @bpHeredoc 1, undefined, 3', '    """', ''].join('\n'));
put(path.join(src, 'BpMixin.coffee'), [
  'BpMixin =', '  onceAddedClassProperties: (fromClass) ->', '    @addInstanceProperties fromClass,', '',
  '    bpMixed: (t) ->', '      inner = -> 1', '      super()', ''].join('\n'));
put(path.join(repo, 'Automator-and-test-harness-src', 'BpHarness.coffee'), ['class BpHarness', '  m: ->', '    @bpCallee 2', ''].join('\n'));
put(path.join(repo, 'tests', 'SystemTest_bp', 'SystemTest_bp_automationCommands.js'),
  'var c = { "mainMacroSource": `m_Macro = ->\n  helper = (a, b) -> a\n  helper undefined, 2\n  @bpCallee 8\n' +
  '  class BpProbe\n    constructor: (a, b, c) -> @a = a\n  new window.BpProbe 1, undefined, 3\n  new BpProbe 1\n` };\n');
put(path.join(repo, 'tests', 'SystemTest_bad', 'SystemTest_bad_automationCommands.js'),
  'var c = { "mainMacroSource": `m_Macro = ->\n  f (\n` };\n');
put(path.join(repo, 'scripts', 's.js'), [
  'function loc(a, b) { return a; }', 'loc(undefined, 1);', 'loc(1, 2);', 'new BpBase(undefined, 2, 3);',
  'a?.bpOptional(undefined, 1);', 'bpSpread(...xs);',
  'class Shard { count = 0; #p = 1; constructor(a, b, c) { this.a = a; } }', 'new Shard(1, undefined, 3);', 'new Shard(1);',
  'function bpLib(a, b, c) { return a; }', 'bpLib(1, undefined, 3);', 'module.exports = { bpLib };',
  'function bpOuter() { function bpInner(a, b) { return a; }', '  bpInner(undefined, 1); }', ''].join('\n'));
put(path.join(repo, 'scripts', 'other.js'), "const lib = require('./s');\nlib.bpLib(1);\n");

let r;
try { r = callSites({ srcDir: src, testsRepoDir: repo }); } finally { fs.rmSync(root, { recursive: true, force: true }); }
const at = (base, line, pred = () => true) => r.sites.filter((s) => path.basename(s.file) === base && s.line === line && pred(s));
const one = (base, line, pred) => { const xs = at(base, line, pred); return xs.length === 1 ? xs[0] : undefined; };
const named = (n) => (s) => s.name === n;

const sup = (line) => one('BpChild.coffee', line, (s) => s.kind === 'super');
t.check(sup(3) && sup(3).args.length === 2 && sup(3).callee.key === 'ctor:BpBase', '`super a, b` is a 2-argument call of the superclass constructor');
t.check(sup(5) && sup(5).args.length === 0 && sup(5).name === 'other', '`super()` is a 0-argument call of the member');
t.check(sup(7) && sup(7).forwarding && !sup(7).knownArity, 'a bare `super` FORWARDS: unknown arity, never a witness');
t.check(one('BpChild.coffee', 12, named('bpOpts'))?.args.length === 2, 'an implicit object is ONE argument');
t.check(one('BpChild.coffee', 13, named('bpNest'))?.args.length === 3, 'a nested paren-less call is ONE argument of the outer call');
t.check(at('BpChild.coffee', 14).length === 0, 'a string holding "x, undefined, 1" is no call');
t.check(one('BpChild.coffee', 15, named('call'))?.callee.excluded, '`.call undefined, …` is excluded: a this-arg');
t.check(one('BpChild.coffee', 16, named('stringify'))?.callee.foreign, 'a name no code defines is foreign');
const shape = (line, n) => one('BpChild.coffee', line, (s) => s.kind === 'new')?.args.length === n;
t.check(shape(17, 0) && shape(18, 1) && shape(19, 2), 'the three call shapes: `new X` (no Call node), `new X(1).p`, `new X 1, 2`');
t.check(one('BpChild.coffee', 17, (s) => s.kind === 'new')?.callee.key === 'ctor:BpBase', 'a `new` is keyed to the class that defines the constructor');
t.check(one('BpChild.coffee', 21, named('visit'))?.callee.key?.startsWith('local:'), 'a member-local function is its own callee');
t.check(one('BpChild.coffee', 22, (s) => s.kind === 'new')?.callee.foreign, 'a dynamic `new` is not judged');
t.check(one('BpChild.coffee', 11, named('bpCallee'))?.candidate === false && one('BpChild.coffee', 11, named('bpCallee')).reach === 1,
  'a trailing `undefined` is no candidate, and reaches 1');
t.check(one('BpToolkit.coffee', 5, named('bpHeredoc'))?.where === 'heredoc', 'a lifted heredoc\'s call IS a call, on its own file line');
t.check(one('BpMixin.coffee', 7, (s) => s.kind === 'super')?.name === 'bpMixed', 'a mixin super is the INNERMOST function-valued member around it');
t.check(one('SystemTest_bp_automationCommands.js', 3, named('helper'))?.callee.key === 'name:helper', 'a macro-local helper is a NAME (macros and verbs link into one program)');
t.check(r.unreadable.some((u) => path.basename(u.file) === 'SystemTest_bad_automationCommands.js'), 'a macro that does not parse is UNREADABLE, never skipped');
t.check(one('s.js', 2, named('loc'))?.callee.key === 'name:loc', 'a JS TOP-LEVEL function is a name (another file may call it)');
t.check(one('s.js', 14, named('bpInner'))?.callee.key?.startsWith('local:'), 'a JS function NESTED in another is its own callee');
t.check(one('s.js', 4, (s) => s.kind === 'new')?.args[0].absent, 'JS `new X(undefined, …)` reads its absence');
t.check(one('s.js', 5, named('bpOptional'))?.args.length === 2, 'a JS optional call is a call');
t.check(one('s.js', 6, named('bpSpread'))?.knownArity === false, 'a JS spread makes the arity unknown');
t.check(one('s.js', 8, (s) => s.kind === 'new')?.callee.key === 'ctor:Shard', 'a class a SCRIPT defines (ES2022 fields and all) is a callee');
t.check(one('BpChild.coffee', 23, (s) => s.kind === 'new')?.callee.key === 'ctor:BpBase', 'a constructor-less subclass\'s `new` is its ancestor\'s constructor');
t.check(one('BpChild.coffee', 25, (s) => s.kind === 'new')?.callee.key === 'ctor:BpChild', '`new @constructor` builds the class it is written in');
t.check(one('bp-globals.coffee', 2, named('bpGlobal'))?.callee.key === 'name:bpGlobal' && one('BpChild.coffee', 24, named('bpGlobal'))?.callee.key === 'name:bpGlobal',
  'a top-level function is ONE callee in its own file and in every other');
t.check(one('SystemTest_bp_automationCommands.js', 7, (s) => s.kind === 'new')?.callee.key === 'ctor:BpProbe', 'a class a MACRO defines is a callee, reached through `new window.X` too');
t.check(r.sites.some((s) => s.where === 'harness' && path.basename(s.file) === 'BpHarness.coffee' && s.name === 'bpCallee'), 'the harness is read: its class fragments are call sites');
t.check(r.unreadable.some((u) => path.basename(u.file) === 'BpInterpolated.coffee' && /computed at run time/.test(u.message)), 'an interpolated heredoc is UNREADABLE, never skipped');

const v = callersTest(r.sites);
const verdict = (base, line, name) => v.holes.find((h) => path.basename(h.site.file) === base && h.site.line === line && h.site.name === name) ? 'HOLE'
  : v.values.find((x) => path.basename(x.site.file) === base && x.site.line === line && x.site.name === name) ? 'VALUE' : 'none';
// line 9's `undefined` reaches 3; line 11 reaches 1 and the macro's `@bpCallee 8` reaches 1: both witnesses
t.check(verdict('BpChild.coffee', 9, 'bpCallee') === 'HOLE', 'the callers test: a site another site OMITS the tail of is a HOLE');
t.check(verdict('s.js', 2, 'loc') === 'VALUE', 'the callers test: a site every caller fills in full is a VALUE');
t.check(verdict('s.js', 4, 'BpBase') === 'HOLE', 'the callers test reads JS `new` sites against CoffeeScript ones');
t.check(verdict('bp-globals.coffee', 2, 'bpGlobal') === 'HOLE', 'a top-level function\'s witness may sit in another file');
t.check(verdict('s.js', 11, 'bpLib') === 'HOLE', 'a JS module function\'s witness may be a `lib.f()` call in another script');
t.check(verdict('s.js', 8, 'Shard') === 'HOLE', 'a script\'s own class is judged');
t.check(verdict('SystemTest_bp_automationCommands.js', 7, 'BpProbe') === 'HOLE', 'a macro\'s own class is judged');
t.done();

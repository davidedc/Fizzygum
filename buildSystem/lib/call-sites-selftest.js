'use strict';
// call-sites-selftest.js — lib/call-sites.js's readings, one case each, on a throwaway fixture: a src tree (the real
// meta/Class.coffee + meta/Mixin.coffee beside a few fixture classes) and a tests repo (a macro, a broken macro, a
// script). Each case names the reading it holds — the three 2.0.3 call shapes, the implicit object, the nested
// paren-less call, the three super forms, a string that is no call, a lifted heredoc on its file line (and an
// interpolated one refused), the trailing absence, the this-arg exclusion, the JS forms (ES2022 included), the
// identities — a constructor-less subclass, a top-level function called from other files, classes a script or a
// macro defines, `new @constructor` — the harness read, and the callers test's value/hole pair; then the arity test's
// readings — each definition's declared count, form and options slot, each send's receiver, each argument's kind, the
// destructured and loop locals, a script's import — and its two verdicts, EXTRA and INTO OPTIONS, with each way a call
// stays unjudged.
// Run by buildSystem/run-selftests.js on every build.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { callSites, callersTest, arityTest } = require('./call-sites');
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
put(path.join(src, 'BpBare.coffee'), ['class BpBare', '  bare: -> 1', ''].join('\n'));
put(path.join(src, 'BpArity.coffee'), [
  'class BpArity extends BpBase',
  '  bpSplat: (a, rest...) -> a',
  '  bpArgs: -> arguments.length',
  '  bpWide: (a, opts = {}) -> a',
  '  bpData: undefined',
  '  bpFwd: (a) ->',
  '    super',
  '  checks: ->',
  '    @bpWide 1, 2, 3',                              // 9: EXTRA — bpWide declares 2
  '    @bpWide 1, @',                                 // 10: INTO OPTIONS — `@` in its `opts = {}` slot
  '    @bpWide 1, face: 2',                           // 11: an object there
  '    @bpSplat 1, 2, 3, 4',                          // 12: a splat: unbounded
  '    @bpArgs 1, 2',                                 // 13: reads `arguments`: unbounded
  '    @bpData 1',                                    // 14: DATA: not judged
  '    Math.bpWide 1, 2, 3',                          // 15: a receiver no reader sees: not judged
  '    BpArity.bpStatic 1, 2',                        // 16: a class-name receiver: EXTRA
  '    cb = (x) -> @bpWide 1, 2, 3',                  // 17: a `->` rebinds `@`: not judged
  '    cb2 = (x) => @bpWide 1, 2, 3',                 // 18: a `=>` keeps it: EXTRA
  '    [f, g] = pair',
  '    f 1, 2, 3',                                    // 20: a destructured local: its own callee, data
  '    for h in hs',
  '      h 1, 2, 3',                                  // 22: a loop variable: its own callee, data
  '    new BpBare 1',                                 // 23: no constructor up the chain: declares 0 — EXTRA
  '    bpTop 1, 2',                                   // 24: a bare call reaches the BINDING (1), not the member (3): EXTRA
  '    @bpFwd 1, 2, 3, 4',                            // 25: a forwarding bare super reads `arguments`: unbounded
  '    @bpWide 1, ("x")',                             // 26: a literal in parentheses — INTO OPTIONS
  '    @bpWide 1, (Object.assign {}, o)',             // 27: an expression in parentheses: no verdict
  '  @bpStatic: (a) -> a',
  '  bpTop: (a, b, c) -> a',
  ''].join('\n'));
put(path.join(src, 'boot', 'bp-top.coffee'), ['bpTop = (a) -> a', ''].join('\n'));
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
  'function bpOuter() { function bpInner(a, b) { return a; }', '  bpInner(undefined, 1); }',
  "const { bpImported } = require('./other');",                     // 15: an import defines nothing
  'bpImported(1, 2);',                                              // 16: EXTRA against other.js's definition (1)
  'function bpO(a, opts = {}) { return a; }',
  "bpO(1, 'x');",                                                   // 18: INTO OPTIONS (a JS literal)
  'class Ring { m(a) { return this.m(1, 2); } }',                   // 19: `this.m` in a method: EXTRA
  'function bpLoop(pairs) { for (const [k, fnx] of pairs) fnx(1, 2); }',   // 20: a nested loop destructuring: local data
  ''].join('\n'));
put(path.join(repo, 'scripts', 'other.js'), "const lib = require('./s');\nlib.bpLib(1);\nfunction bpImported(a) { return a; }\n");

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

// ---- the arity test ----
const def = (key, pred = () => true) => (r.defs.get(key) || []).filter(pred);
const wide = def('name:bpWide', (d) => d.form === 'member')[0];
t.check(wide && wide.fn && wide.arity === 2 && wide.optsAt === 1, 'a member declares its parameter count and its `opts = {}` slot');
t.check(def('name:bpSplat')[0]?.arity === Infinity && def('name:bpArgs')[0]?.arity === Infinity && def('name:bpFwd')[0]?.arity === Infinity,
  'a splat, a body reading `arguments` and a forwarding bare `super` declare any number');
t.check(def('name:bpData')[0]?.fn === false, 'a data member is DATA: no arity');
t.check(def('name:bpTop', (d) => d.form === 'binding')[0]?.arity === 1 && def('name:bpTop', (d) => d.form === 'member')[0]?.arity === 3,
  'a top-level function is a BINDING, a class member of the same name a MEMBER');
t.check(def('ctor:BpBase')[0]?.form === 'member' && def('ctor:BpBase')[0].arity === 3, 'a constructor is its class\'s `ctor:` definition');
t.check(def('name:x', (d) => d.form === 'field').length > 0, '`@x = a` defines a FIELD');
t.check(one('BpArity.coffee', 20, named('f'))?.callee.key?.startsWith('local:') && one('BpArity.coffee', 22, named('h'))?.callee.key?.startsWith('local:'),
  'a destructured and a loop variable are LOCALS');
t.check(one('s.js', 20, named('fnx'))?.callee.key?.startsWith('local:'), 'a JS destructured loop variable is a LOCAL');
t.check(def('name:bpImported').length === 1, 'a name a script destructures from `require(…)` is an import: it defines nothing');
t.check(one('BpArity.coffee', 9, named('bpWide'))?.via === 'this' && !one('BpArity.coffee', 17, named('bpWide'))?.via
  && one('BpArity.coffee', 18, named('bpWide'))?.via === 'this' && one('BpArity.coffee', 16, named('bpStatic'))?.via === 'name:BpArity',
  'a send\'s receiver: `@` at its member\'s level and under `=>`, not under `->`; `X.m` names X');
const kinds = (line) => one('BpArity.coffee', line, named('bpWide'))?.args.map((a) => a.kind).join(' ');
t.check(kinds(10) === 'literal this' && kinds(11) === 'literal object' && kinds(26) === 'literal literal' && kinds(27) === 'literal expression',
  'an argument\'s kind is what its parse shows, through parentheses');
const a = arityTest(r);
const extra = (base, line, name) => a.extra.some((x) => path.basename(x.site.file) === base && x.site.line === line && x.site.name === name);
const opts = (base, line, name) => a.intoOptions.some((x) => path.basename(x.site.file) === base && x.site.line === line && x.site.name === name);
t.check(extra('BpArity.coffee', 9, 'bpWide') && extra('BpArity.coffee', 18, 'bpWide') && extra('BpArity.coffee', 16, 'bpStatic'), 'EXTRA: a call passing more than its callee declares');
t.check(!['bpSplat', 'bpArgs', 'bpData', 'bpFwd'].some((n) => a.extra.some((x) => x.site.name === n)), 'an unbounded or DATA callee is not judged');
t.check(!extra('BpArity.coffee', 15, 'bpWide') && !extra('BpArity.coffee', 17, 'bpWide'), 'a receiver no reader sees (`Math.m`, `@` under `->`) is not judged');
t.check(!extra('BpArity.coffee', 20, 'f') && !extra('BpArity.coffee', 22, 'h'), 'a destructured or loop variable is DATA: not judged');
t.check(extra('BpArity.coffee', 23, 'BpBare'), 'a class with no constructor up its chain takes none');
t.check(extra('BpArity.coffee', 24, 'bpTop'), 'a bare call is judged against the BINDINGS of its name, never a member');
t.check(extra('s.js', 16, 'bpImported') && extra('s.js', 19, 'm'), 'JS: an imported function, and `this.m` in a class method');
t.check(!a.extra.some((x) => x.site.name === 'bpLeafy') && !extra('BpChild.coffee', 23, 'BpLeaf'), 'a constructor-less subclass takes its ancestor\'s parameters');
t.check(opts('BpArity.coffee', 10, 'bpWide') && opts('BpArity.coffee', 26, 'bpWide') && opts('s.js', 18, 'bpO'), 'INTO OPTIONS: `@` or a literal in an `opts = {}` slot');
t.check(!opts('BpArity.coffee', 11, 'bpWide') && !opts('BpArity.coffee', 27, 'bpWide'), 'an object, or an expression, in the options slot is no verdict');

// ---- the arity test never judges a call against definitions that may not hold its target (each a correct program
// a by-name, per-file or receiver-blind reading would fail) ----
const fixture = (files) => {
  const root2 = fs.mkdtempSync(path.join(os.tmpdir(), 'call-sites-reach-'));
  try {
    for (const m of ['Class.coffee', 'Mixin.coffee']) put(path.join(root2, 'src', 'meta', m), fs.readFileSync(path.join(REAL_SRC, 'meta', m), 'utf8'));
    put(path.join(root2, 'tests-repo', 'Automator-and-test-harness-src', 'H.coffee'), 'class H\n  h: -> 1\n');
    fs.mkdirSync(path.join(root2, 'tests-repo', 'tests'), { recursive: true });
    for (const [rel, text] of Object.entries(files)) put(path.join(root2, rel), text);
    const table = callSites({ srcDir: path.join(root2, 'src'), testsRepoDir: path.join(root2, 'tests-repo') });
    // every fixture file was READ — a reading that skipped one would pass its case on nothing
    const read = new Set([...table.sites, ...[...table.defs.values()].flat()].map((x) => path.relative(root2, x.file)));
    const unread = Object.keys(files).filter((f) => !read.has(f));
    if (unread.length || !table.counts.testsRepo || table.unreadable.length) throw new Error('fixture not read: ' + unread.join(', ') + JSON.stringify(table.unreadable));
    return table;
  } finally { fs.rmSync(root2, { recursive: true, force: true }); }
};
const extras = (files) => arityTest(fixture(files)).extra.map((x) => path.basename(x.site.file) + ':' + x.site.line);
const tm = (name, body) => ({ ['tests-repo/tests/SystemTest_' + name + '/SystemTest_' + name + '_automationCommands.js']: 'var c = { "mainMacroSource": `m_Macro = ->\n' + body + '\n` };\n' });
t.check(extras({ 'tests-repo/scripts/bus.js': 'class Bus extends EventEmitter { on(ev) { return super.on(ev, () => {}); } put(k) { this.set(k, 1); } }\n',
    'src/BpOn.coffee': 'class BpOn\n  on: (a) -> a\n  set: (v) -> v\n',
    'src/BpQueue.coffee': 'class BpQueue extends Array\n  addTwo: (a, b) -> @push a, b\n', 'src/BpPusher.coffee': 'class BpPusher\n  push: (x) -> x\n' }).length === 0,
  'a class whose chain ends in a FOREIGN base (EventEmitter, Array): its `this`/`super` sends are not judged');
t.check(extras({ 'tests-repo/scripts/bus2.js': 'class Bus2 extends events.EventEmitter {}\nnew Bus2({ captureRejections: true });\n' }).length === 0,
  'a class extending a COMPUTED parent (`events.EventEmitter`) has no known constructor');
t.check(extras({ ...tm('a', '  class BpTwin\n  new BpTwin'), ...tm('b', '  class BpTwin\n    constructor: (a, b) -> @a = a\n  new BpTwin 1, 2') }).length === 0,
  'two macro programs each defining a class of one name: each `new` reaches its OWN program\'s');
t.check(extras({ 'tests-repo/scripts/img.js': 'class Image { constructor() {} }\n', 'src/BpImg.coffee': 'class BpImg\n  m: -> new Image 10, 10\n' }).length === 0,
  'a class a SCRIPT defines is invisible to page code (CoffeeScript\'s `new Image` is the browser\'s)');
t.check(extras({ 'tests-repo/scripts/fmt.js': "const { format } = require('util');\nformat('%s-%s', 'a', 'b');\n", 'src/boot/fmt.coffee': 'format = (s) -> s\n',
    'tests-repo/scripts/ren.js': "const { wide: go } = require('./lib6');\ngo(1, 2, 3);\n", 'tests-repo/scripts/lib6.js': 'function wide(a, b, c) { return a; }\nmodule.exports = { wide };\n',
    'tests-repo/scripts/other6.js': 'function go(a) { return a; }\n' }).length === 0,
  'a name imported from a FOREIGN module, or renamed, reaches no binding the reader sees: no same-named one elsewhere stands in');
t.check(extras({ 'tests-repo/scripts/op.js': 'function open(p) { return p; }\n', 'src/BpOpen.coffee': 'class BpOpen\n  m: -> open "http://x", "_blank"\n' }).length === 0,
  'a script\'s function is invisible to page code (a bare `open` there is the browser\'s)');
t.check(extras({ 'src/boot/hlp.coffee': 'helper = (a, b) -> a\n', 'src/BpHelp.coffee': 'class BpHelp\n  m: ->\n    cb = ->\n      helper = (a) -> a\n      helper 1\n    helper 1, 2\n',
    'tests-repo/scripts/sh.js': 'function helper2(a, b) { return a; }\nfunction f() { const helper2 = (a) => a; return helper2(1); }\nhelper2(1, 2);\n',
    'src/boot/cap.coffee': 'cap = (a, b) -> a\ng = ->\n  cap 1, 2\n  cap = (a) -> a\n' }).length === 0,
  'LEXICAL scope: a binding nested in an inner function does not capture a call made outside it (CoffeeScript, JS); a CoffeeScript assignment inside a function to a name the top level assigns IS the top-level one');
t.check(extras({ 'tests-repo/scripts/run.js': 'function run(a) { return a; }\nfunction g(xs) { for (const run of xs) run(); }\nrun(1, 2, 3);\n' }).join() === 'run.js:3',
  'a top-level call reaches the top-level function, past a same-named nested loop variable: judged');
t.check(extras({ 'src/boot/foo.coffee': 'foo = (a, b) -> a\n@foo 1, 2\n', 'src/BpFoo.coffee': 'class BpFoo\n  foo: (a) -> a\n' }).length === 0,
  'a boot file\'s top-level `@` is `window`, not a class: its sends are not judged');
t.check(extras({ 'src/BpMx.coffee': 'BpMxMixin =\n\n  onceAddedClassProperties: (fromClass) ->\n    [1].forEach (x) -> @foo 1, 2\n    @addInstanceProperties fromClass,\n\n      build: ->\n        @spec\n          render: (a) -> a\n',
    'src/BpFoo2.coffee': 'class BpFoo2\n  foo: (a) -> a\n', 'src/BpRender.coffee': 'class BpRender\n  m: -> @render 1, 2\n' }).length === 0,
  'a mixin: a `->` that is not one of its members rebinds `@`; a call no member or field anywhere defines is not judged');
t.check(extras({ 'src/BpGo.coffee': 'class BpGo\n  m: -> @go 1, 2\n', 'src/BpGo2.coffee': 'class BpGo2\n  go: (a) -> a\n',
    'src/boot/go.coffee': 'impl = { go: (a, b) -> a }\nfor k, v of impl\n  BpGo::[k] = v\n' }).length === 0,
  'a function under an object key reaches a send too (a computed install `X::[k] = v`): it widens, never narrows');
t.check(extras({ 'tests-repo/scripts/k.js': 'class K {\n  get handler() { return (a, b) => a; }\n  go() { return this.handler(1, 2); }\n}\n' }).length === 0,
  'a JS getter is not the callable: `this.h(1, 2)` calls what it returns');
t.check(extras({ 'tests-repo/scripts/f.js': 'class F {\n  handler = (a) => a;\n  go() { return this.handler(1, 2); }\n}\n' }).join() === 'f.js:3',
  'a JS class field holding a function is a member, judged');
t.check(extras({ 'src/BpSelf.coffee': 'class BpSelf\n  constructor: (a) -> @a = a\n  clone: -> new @constructor 1, 2\n', 'src/BpSub.coffee': 'class BpSub extends BpSelf\n  constructor: (a, b) -> super a\n' }).length === 0,
  '`new @constructor` may build a subclass: not judged');
t.done();

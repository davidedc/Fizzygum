#!/usr/bin/env node
'use strict';
/*
 * check-part-edges.js — build gate: CORE must never reach into a PART without a guard.
 *
 * THE FAILURE MODE THIS EXISTS FOR. buildSystem/parts.json splits the shipped source into a core
 * plus named parts, and a part can be absent (the production profile ships two) or, from arc 4
 * phase 2, not yet loaded. If core code names a part's class unconditionally, then on the artifact
 * that lacks it the reference throws `<TheClass> is not defined` — at the moment the user clicks,
 * deep in a UI no gate boots into. The suite runs the HARNESS page, which carries every part; the
 * boot smoke boots and rotates a widget. Neither opens the menu item that constructs a
 * part-owned widget. So nothing else in this repo can catch this, which is why it is a build gate
 * and not a test.
 *
 * ⚠ WHY IT IS NOT DERIVED FROM THE DEPENDENCY SCANNER. src/boot/dependencies-finding.coffee, which
 * computes the boot load order, matches only five patterns: `\sextends\s*(\w+)`,
 * `\sREQUIRES\s*(\w+)`, `\s*@augmentWith\s+(\w+)`, and two restricted to a 2-space-indented
 * CLASS-BODY FIELD INITIALISER (`^\s\s@?ident\s*:\s*new\s*(Ident)` / `^\s\s@?ident\s*:\s*([A-Z]…)`).
 * A `new X` inside a METHOD BODY is invisible to it — and a method body is where every real launch
 * site lives. Aggregating that scan to part granularity (the original plan) would therefore have
 * reported ZERO core->part edges and passed vacuously. Hence the blunt instrument below: scan core
 * source text for each part-owned class NAME.
 *
 * TWO KINDS OF EDGE, TWO VERDICTS:
 *   - a REFERENCE (a construction, a static call, a mention) is fixable where it stands: guard it
 *     with `if TheClass?` for an eager part, or await `world.parts.ensureLoaded` for a lazy one.
 *   - `extends X` / `@augmentWith X` is NOT guardable at all — you cannot conditionally derive a
 *     class or conditionally mix in a mixin. It means the PARTITION IS WRONG: the base class or
 *     mixin is core material. Reported separately, and never with a "add a guard" suggestion.
 *
 * WHAT COUNTS AS GUARDED (an occurrence is allowed if any holds):
 *   1. it is inside a `#` comment — prose may name anything;
 *   2. it is inside a string literal — a class NAME as data is exactly the sanctioned indirection;
 *   3. the same line carries `SomeClass?` (covers `… if TheClass?`, `if TheClass? then …`,
 *      `TheClass?.something`, `(new TheClass) if TheClass?`);
 *   4. it is INSIDE THE SCOPE of such a guard — i.e. on a following line indented deeper than the
 *      guard's own line. That one rule covers both shapes the tree actually uses — SKETCHED below
 *      rather than quoted: what the rule turns on is the INDENTATION relationship, and the real
 *      sites say more on the guarded line than fits here:
 *        if Automator?                     |  if Automator? and
 *          @automator = …Automator…        |      Automator.animationsPacingControl and
 *                                          |      Automator.state == Automator.PLAYING
 *      the guarded block (any number of deeper-indented lines, comments among them), and the
 *      multi-line boolean continuation;
 *   5. the enclosing method opens with a `return unless TheClass?` / `return if !TheClass?` bail-out
 *      (the idiom Widget.becomeAPointer uses), which guards the whole rest of the method.
 *
 * A GUARD IS PER-PART, NOT PER-CLASS. `if AutomatorPlayer? and Automator.state == …` is correctly
 * guarded even though the tested class and the used class differ: both belong to the 'harness' part,
 * and a part is all-or-nothing — if one of its classes is here, all of them are. So a guard on any
 * class of part P protects references to every class of part P.
 *
 * ⚠⚠ ONE DELIBERATE BLIND SPOT — DO NOT "FIX" IT. `new (window[className])` after an
 * `ensureLoaded`, and `world.parts.launch "SomeClass"`, contain no bare class identifier, so this
 * gate cannot see them. That is BY DESIGN and it is the prescribed shape for a lazy part: core names
 * the class as DATA (from the manifest, or from its caller) rather than as a SYMBOL the loader must
 * have already defined. Teaching this gate to chase string literals through `window[…]` would flag
 * the correct pattern and push authors back to the broken one. The safety net for that path is the
 * ensure promise itself, plus the lazy path's own SystemTest.
 *
 * SCOPE: EVERY source that is present at boot -- core AND every eager part -- plus each lazy part
 * measured against the parts it does not declare in `requires`. It used to be core alone, on the
 * stated premise that part-to-part references were "legitimate when the manifest declares the
 * dependency"; no such mechanism existed, so that premise excused exactly nothing and the hole
 * shipped four broken doors (BouncerWdgt/PenWdgt from dev-tools, the two map icons from demos --
 * each threw '<Class> is not defined' on a real menu click). An EAGER part is in the artifact from
 * the first frame exactly as core is, so it has to obey the same rule.
 *
 * WHAT SATISFIES A REFERENCE INTO ANOTHER PART, beyond the guards above:
 *   6. AN AWAIT IS A GUARD. `world.parts.whenAllLoaded ["maps"], ->` opens a scope, exactly as
 *      `if X?` does, and every deeper-indented line under it runs with that part present. Not
 *      teaching this gate the idiom it exists to encourage was its worst false positive: it
 *      demanded a guard at sites that had correctly awaited, which pushes an author toward
 *      `if X?` -- the ONE idiom that is wrong for a lazy part, because it silently swallows the
 *      click instead of fetching. ⚠ whenOptionalPartsLoaded does NOT count: it runs its callback
 *      even when the part never arrives, so those references still need their own guard.
 *   7. A CLASS-LEVEL `requiredParts: [...]` covers the whole file. It is the list an
 *      WindowedApp's inherited `launch` awaits before calling buildWindow, so
 *      the declaration and the await cannot drift -- the await IS the declaration. This exists
 *      because the gate reads one line at a time and can never see that a `launch` three methods
 *      up already awaited; before it, nine apps awaited correctly and still failed the gate, which
 *      is what forced the authoring/authoring-launcher split.
 *   8. parts.json `requires` covers a LAZY part naming another part. There PartsRegistry loads the
 *      required parts FULLY FIRST, so the classes are defined before this part is even ingested.
 *      ⚠ It does NOT excuse an EAGER part naming a LAZY one: that owner is already running at boot,
 *      so `requires` can only promise the other part SHIPS, never that it has arrived. Hence the
 *      asymmetry -- eager->lazy still needs a guard or an await where it stands, and
 *      `declaredRequires` filters those entries out. (eager->EAGER is fine: both are in the
 *      artifact from frame one, so shipping-together is the whole of what could go wrong.)
 *
 * ⛔ CROSS-PART INHERITANCE is only safe under `requires`. A door naming several parts goes through
 * ensureAllLoaded = Promise.all, so they arrive concurrently with nothing ordering them, and
 * `class X extends Y` across that boundary is a race rather than a catchable error. Only
 * findLoadOrder (inside one part) and `requires` (between parts) order anything.
 *
 * INSTALLED MEMBERS ARE A PART'S SYMBOLS TOO. A part can put members onto a class it does not own:
 * the harness's `*TestSupport` classes are copied onto core prototypes at boot
 * (`WorldTestSupport.installOnto WorldWdgt` in src/boot/globalFunctions.coffee). The edges, and what
 * each one copies by installOnto's own semantics, come from lib/install-edges.js, which
 * check-menu-actions.js reads too. On an artifact without that part such a member does not exist, so
 * a caller of it throws -- or a row dispatching it by name is dead -- exactly as a reference to one of
 * the part's classes would. The name-resolution gates cannot see this, by construction:
 * check-unresolved-sends.js and check-menu-actions.js count the harness in their definition universe,
 * correctly, because their question is "does ANYTHING implement this?". The question here is "is it
 * there on every build that ships the caller?", so the rule lives here:
 *   - a member is part P's SYMBOL when P installs it onto a class outside P and NO file outside P
 *     that can ship (src/boot included) defines it -- by the implementor harvest
 *     check-unresolved-sends.js reads too (lib/name-definitions.js: a method, a static, a field, a
 *     key or an assignment target, OVER-approximated in the direction that flags less). Then on a
 *     build without P nothing implements it, whatever the receiver, and that is what makes the
 *     receiver-blind clauses (a) and (b) sound rather than guesses;
 *   - in a file whose part is not P and is not satisfied for P (the class rule's own `requires` /
 *     `requiredParts` reading), each of these is a violation unless its line is guarded for P:
 *       (a) a code reference `@m` / `x.m` -- a call or a read -- that is not an existence test `m?`;
 *       (b) a string literal whose whole content is `m` -- dispatch BY NAME (a menu row's or a
 *           button's action, `@[name]`), the commonest way an installed member is reached;
 *       (c) a `super` in a method named m of a class outside P, when P installs m onto that class or
 *           an ancestor and no class outside P above it defines m: without P that super has nowhere
 *           to go. This clause reads EVERY installed m, P's alone or not, because what matters is
 *           what the super finds, and the class model (census-public-private-calls.js's chainOf)
 *           answers exactly that;
 *   - an existence test on a member P alone provides -- `@m?()`, `x.m? arg`, `if x.m?`,
 *     `return unless x.m?` -- GUARDS for P exactly as `if X?` on one of P's classes does, opening the
 *     same scope (lib/part-edge-scan.js): a part is all-or-nothing, so one of its members being here
 *     proves all of it is.
 *   WHAT THIS CANNOT SEE: a call or a by-name dispatch of an installed member that some class
 *   outside P ALSO defines (the harness's spacer sweep, which LayoutSpacerWdgt overrides): such a
 *   site is dead without P on some receivers and fine on others, and a receiver-blind scan cannot
 *   tell which, so only its `super` is judged, by (c); a member reached through a COMPUTED name
 *   (`x[name]()` with the name built at runtime or arriving as data, or a string that only CONTAINS
 *   the name); a reference inside a `#{…}` interpolation, which codePartOf masks with the string
 *   around it; src/boot itself, which is outside the scanned set for both rules; a `super` in a
 *   CLASS-SIDE method (the class model holds instance members only); and a member put on a class by
 *   anything other than an `installOnto` edge in src/boot/globalFunctions.coffee --
 *   lib/install-edges.js fails loudly on an `installOnto` whose body it does not model, but it cannot
 *   find what is not an edge. With the sibling tests repo absent there are no support classes to
 *   read, so this half SKIPS, as check-menu-actions.js's RULE 1b does, rather than report a
 *   harness-less checkout clean.
 *
 * `--self-test` drives the installed-member half -- which members count as a part's own, the three
 * clauses and the member existence guard -- over in-memory fixtures, each clause both ways; it needs
 * no repo. (The definition forms themselves are pinned by check-unresolved-sends.js --self-test.)
 */

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
// strip trailing `# comment` while respecting quotes, and report whether code remains
const { codePartOf, stringLiteralsOf, guardedPartsPerLine } = require('./lib/part-edge-scan');
const { installEdges, harnessPresent } = require('./lib/install-edges');
const { harvestDefs } = require('./lib/name-definitions');

const REPO = path.resolve(__dirname, '..');
const PARTS_FILE = path.join(REPO, 'buildSystem/parts.json');

function fail(msg) { console.error('check-part-edges: ' + msg); process.exit(2); }

// ---- installed members: the pure half (what --self-test drives) ------------------------------

// Which installed members are their part's SYMBOL. `installedBy` maps a member name to the Set of
// parts installing it onto a class outside themselves; `files` is [{ part, lines }] for everything
// that can ship. A member qualifies when exactly one part installs it and no file of any OTHER part
// defines it, by the implementor harvest check-unresolved-sends.js reads too
// (lib/name-definitions.js). That harvest over-approximates, so an extra "definition" can only
// withdraw a member here, never add one. Returns Map(member -> part).
function soleProviders(installedBy, files) {
  const definingParts = new Map();    // member name -> Set(parts whose files define it)
  for (const { part, lines } of files) {
    for (const name of harvestDefs(lines)) {
      if (!installedBy.has(name)) continue;
      if (!definingParts.has(name)) definingParts.set(name, new Set());
      definingParts.get(name).add(part);
    }
  }
  const out = new Map();
  for (const [name, installers] of installedBy) {
    if (installers.size !== 1) continue;
    const [part] = installers;
    if ([...(definingParts.get(name) || [])].every(p => p === part)) out.set(name, part);
  }
  return out;
}

// Clauses (a) and (b) over one file. `soleProvider` maps a member name to the part that alone
// provides it; `owner` is the file's part and `isSatisfied(part)` the class rule's requires/
// requiredParts answer for it. Returns [{ line, clause, name, part }], one per (line, clause, name).
function memberReaches(lines, guards, soleProvider, owner, isSatisfied) {
  const out = [];
  const seen = new Set();
  const report = (i, clause, name, part) => {
    const key = i + ' ' + clause + ' ' + name;
    if (seen.has(key)) return;
    seen.add(key);
    out.push({ line: i + 1, clause, name, part });
  };
  const reaches = (name, i) => {
    const part = soleProvider.get(name);
    if (!part || part === owner || isSatisfied(part) || guards[i].has(part)) return undefined;
    return part;
  };
  const REF = /[@.]([A-Za-z_$][\w$]*)/g;
  for (let i = 0; i < lines.length; i++) {
    const code = codePartOf(lines[i]);
    let m;
    REF.lastIndex = 0;
    while ((m = REF.exec(code)) !== null) {
      if (code[m.index + m[0].length] === '?') continue;     // an existence test: a guard, not a reach
      const part = reaches(m[1], i);
      if (part) report(i, 'a', m[1], part);
    }
    for (const s of stringLiteralsOf(lines[i])) {
      const part = reaches(s, i);
      if (part) report(i, 'b', s, part);
    }
  }
  return out;
}

// Clause (c). `classModel` is census-public-private-calls.js's { classInfo, chainOf } (instance
// methods, bodies already stripped of comments and strings); `installedOn` maps a class name to
// Map(member -> installing part), prototype members only, since a super walks the prototype chain;
// `partOfClass(name)` answers a class's part; `fileOf(name)` answers { rel, owner, guards,
// isSatisfied } for a class whose file is scanned, else undefined.
const SUPER = /\bsuper\b(?!\s*(?:\.|::))/;     // `super.other()` reaches a DIFFERENT member
function superReaches(classModel, installedOn, partOfClass, fileOf) {
  const out = [];
  for (const [cls, info] of classModel.classInfo) {
    const file = fileOf(cls);
    if (!file) continue;
    const chain = classModel.chainOf(cls);
    for (const [name, rec] of info.methods) {
      let part;
      for (const c of chain) {
        const installed = installedOn.get(c.name);
        if (installed && installed.has(name)) { part = installed.get(name); break; }
      }
      if (!part || part === file.owner || file.isSatisfied(part)) continue;
      if (chain.slice(1).some(c => c.methods.has(name) && partOfClass(c.name) !== part)) continue;
      for (const { n, code } of rec.bodyLines) {
        if (!SUPER.test(code) || file.guards[n - 1].has(part)) continue;
        out.push({ rel: file.rel, line: n, clause: 'c', name, part, cls });
      }
    }
  }
  return out;
}

// ---- --self-test: every clause both ways, on in-memory fixtures ------------------------------
if (process.argv.includes('--self-test')) {
  let ok = true;
  const check = (label, got, want) => {
    const pass = JSON.stringify(got) === JSON.stringify(want);
    console[pass ? 'log' : 'error'](`  ${pass ? 'ok  ' : 'FAIL'} ${label} -> ${JSON.stringify(got)}${pass ? '' : ` (expected ${JSON.stringify(want)})`}`);
    if (!pass) ok = false;
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

  console.log(ok ? '[part-edges] self-test PASS' : '[part-edges] self-test FAIL');
  process.exit(ok ? 0 : 1);
}

let parts;
try {
  parts = JSON.parse(fs.readFileSync(PARTS_FILE, 'utf8')).parts;
} catch (e) {
  fail('cannot read buildSystem/parts.json: ' + e.message);
}

// ---- which file belongs to which part -------------------------------------------------------
let shippable;
try {
  shippable = execFileSync('python3', ['-B', 'buildSystem/build.py', '--list-shippable'],
    { cwd: REPO, encoding: 'utf8' }).split('\n').filter(Boolean);
} catch (e) {
  fail('build.py --list-shippable failed: ' + e.message);
}

const dirToPart = new Map();
for (const [partName, part] of Object.entries(parts)) {
  if (partName.startsWith('//')) continue;
  for (const d of part.dirs || []) dirToPart.set(path.posix.normalize(d), partName);
}

const isLazy = (partName) => partName !== 'core' && !!parts[partName] && parts[partName].eager === false;
// What a part may name without guarding: itself, plus the `requires` entries that actually cover
// the reference. ⚠⚠ `requires` MEANS TWO DIFFERENT THINGS AND ONLY ONE OF THEM IS ENOUGH HERE:
// it always promises the other part SHIPS (buildProfile.py refuses a profile missing it), but it
// promises the classes have ARRIVED only when the OWNER is lazy -- there PartsRegistry brings the
// requirements fully in before ingesting this part. An EAGER owner is running from the first frame,
// so a LAZY requirement may not be here yet and that site still needs a guard or an await where it
// stands. An eager->EAGER requirement is fine: both are in the artifact from frame one, and
// shipping-together is the whole of what could go wrong.
//
// ⚠ This asymmetry is the one the header describes, and until 2026-08-02 the code did NOT implement
// it -- every owner got its full `requires` list, and the check below tests this set BEFORE the
// inheritance check, so an eager part declaring `requires` on a lazy one could both reference and
// `extends` its classes with the build staying green. Proven by planting each shape in 'dev-tools'
// against the lazy 'app-kit': both reported 0 violations. Do not "simplify" this back.
const declaredRequires = (partName) => {
  const required = ((parts[partName] || {}).requires) || [];
  const ownerIsLazy = isLazy(partName);
  return new Set([partName, ...required.filter(r => ownerIsLazy || !isLazy(r))]);
};

const coreFiles = [];
const partClassOwner = new Map();   // ClassName -> partName (non-core parts only)
for (const rel of shippable) {
  const dir = path.posix.dirname(rel);
  const owner = dirToPart.get(path.posix.normalize(dir));
  if (!owner) continue;             // check-shippable-coverage.js is what fails on this
  if (owner === 'core') coreFiles.push(rel);
  else partClassOwner.set(path.basename(rel, '.coffee'), owner);
}

if (!partClassOwner.size) fail('no part-owned classes found — is parts.json only core?');

// ---- scan ------------------------------------------------------------------------------------
// Sort names longest-first so a name that is a SUFFIX of another (PointerWdgt inside
// ActivePointerWdgt) cannot be mis-attributed; \b anchors handle it, this just keeps reports tidy.
const names = [...partClassOwner.keys()].sort((a, b) => b.length - a.length);
const patterns = names.map(n => ({
  name: n,
  owner: partClassOwner.get(n),
  // \b would match inside ActivePointerWdgt for the SUFFIX PointerWdgt only if preceded by a
  // non-word char, which it is not — so \b is sufficient. Verified against that exact pair.
  ref: new RegExp('\\b' + n + '\\b'),
  inherit: new RegExp('(?:\\bextends\\s+' + n + '\\b)|(?:@augmentWith\\s+' + n + '\\b)')
}));

const refViolations = [];
const inheritViolations = [];
const memberViolations = [];

// EVERY file that is present at boot is in scope, not just core's. An EAGER part is in the artifact
// from the first frame exactly as core is, so `samples` naming a lazy `plots` class unguarded is the
// same defect as core doing it -- and it was invisible for as long as this gate looked only at core.
// A LAZY part is in scope too, against the parts it does NOT declare in `requires`.
const scanned = [...shippable].filter(rel => dirToPart.get(path.posix.normalize(path.posix.dirname(rel))));
const partOfFile = (rel) => dirToPart.get(path.posix.normalize(path.posix.dirname(rel)));

// ---- installed members (see the header) ------------------------------------------------------
// classOf -> part for EVERY shipped class, core included: an install edge crosses a part boundary
// only when its support class and its target live in different parts.
const ownerOfAnyClass = new Map();
for (const rel of scanned) ownerOfAnyClass.set(path.basename(rel, '.coffee'), partOfFile(rel));
const partOfClass = (name) => ownerOfAnyClass.get(name) || 'core';

const membersSkipped = harnessPresent() ? '' :
  'sibling Fizzygum-tests not present (its *TestSupport classes are what installs the members)';
const installedBy = new Map();     // member name -> Set(parts installing it onto a class outside themselves)
const installedOn = new Map();     // target class -> Map(prototype member -> installing part), for clause (c)
let edgeCount = 0;
if (!membersSkipped) {
  let edges;
  try { edges = installEdges(); } catch (e) { fail(e.message); }
  for (const edge of edges) {
    const part = ownerOfAnyClass.get(edge.support);
    if (!part || part === partOfClass(edge.target)) continue;
    edgeCount++;
    if (!installedOn.has(edge.target)) installedOn.set(edge.target, new Map());
    for (const m of edge.members) {
      if (!installedBy.has(m.name)) installedBy.set(m.name, new Set());
      installedBy.get(m.name).add(part);
      if (!m.isStatic) installedOn.get(edge.target).set(m.name, part);
    }
  }
}

// A member is its part's SYMBOL only if no file outside that part can define it. The definition
// universe is everything that ships -- every part's files, and src/boot, which is in every bundle.
const shippedFiles = [];             // [{ part, lines }]
if (installedBy.size) {
  const bootFiles = [];
  const walkBoot = (dir) => {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      const p = path.join(dir, e.name);
      if (e.isDirectory()) walkBoot(p);
      else if (e.name.endsWith('.coffee')) bootFiles.push(path.relative(REPO, p));
    }
  };
  walkBoot(path.join(REPO, 'src/boot'));
  for (const rel of [...scanned, ...bootFiles]) {
    let lines;
    try { lines = fs.readFileSync(path.join(REPO, rel), 'utf8').split('\n'); } catch (e) { continue; }
    shippedFiles.push({ part: partOfFile(rel) || 'core', lines });
  }
}
const soleProvider = soleProviders(installedBy, shippedFiles);   // member name -> the one part that provides it

const scannedFileOfClass = new Map();   // class name -> { rel, owner, guards, isSatisfied }, for clause (c)

for (const rel of scanned) {
  const owner = partOfFile(rel);
  const abs = path.join(REPO, rel);
  let lines;
  try { lines = fs.readFileSync(abs, 'utf8').split('\n'); } catch (e) { continue; }
  const guards = guardedPartsPerLine(lines, partClassOwner, parts, soleProvider);
  const satisfied = declaredRequires(owner);

  // A CLASS-LEVEL DECLARATION covers the whole file. `requiredParts: ["authoring"]` on an
  // WindowedApp subclass is the list its inherited `launch` awaits before it
  // calls buildWindow, so every reference in that class runs with those parts in. The gate reads
  // one line at a time and could never infer that; reading the declaration is how it learns.
  // ⚠ `optionalParts` deliberately does NOT count -- that idiom runs the callback even when the
  // part never arrived, so those references still need a guard of their own.
  const declared = /^\s*requiredParts\s*:\s*\[([^\]]*)\]/m.exec(lines.join('\n'));
  if (declared) {
    for (const q of declared[1].match(/["']([^"']+)["']/g) || []) satisfied.add(q.slice(1, -1));
  }

  for (let i = 0; i < lines.length; i++) {
    const code = codePartOf(lines[i]);
    if (!code.trim()) continue;
    for (const p of patterns) {
      if (p.owner === owner || satisfied.has(p.owner)) continue;
      if (!p.ref.test(code)) continue;
      if (p.inherit.test(code)) {
        inheritViolations.push({ rel, from: owner, line: i + 1, name: p.name, owner: p.owner, text: lines[i].trim() });
        continue;
      }
      if (guards[i].has(p.owner)) continue;
      refViolations.push({ rel, from: owner, line: i + 1, name: p.name, owner: p.owner, text: lines[i].trim(),
                           lazy: isLazy(p.owner) });
    }
  }

  // the installed-member clauses (a) and (b), against the same requires/requiredParts reading
  const isSatisfied = (part) => satisfied.has(part);
  for (const v of memberReaches(lines, guards, soleProvider, owner, isSatisfied)) {
    memberViolations.push({ rel, from: owner, ...v, text: lines[v.line - 1].trim() });
  }
  scannedFileOfClass.set(path.basename(rel, '.coffee'), { rel, owner, guards, isSatisfied, lines });
}

// clause (c) needs the class model -- whose chain a `super` walks -- which is
// census-public-private-calls.js's, reused rather than re-derived (check-menu-actions.js does the same).
if (installedOn.size) {
  const { classInfo, chainOf } = require('./census-public-private-calls.js').runCensus();
  for (const v of superReaches({ classInfo, chainOf }, installedOn, partOfClass, (n) => scannedFileOfClass.get(n))) {
    const file = scannedFileOfClass.get(v.cls);
    memberViolations.push({ ...v, from: file.owner, text: file.lines[v.line - 1].trim() });
  }
}

console.log(`[part-edges] scan done — ${scanned.length} source(s) present at boot or in a part vs ` +
  `${partClassOwner.size} part-owned class(es) in ${new Set(partClassOwner.values()).size} part(s)` +
  (membersSkipped ? `; installed members SKIPPED -- ${membersSkipped}` :
    ` and ${installedBy.size} member(s) that ${edgeCount} install edge(s) put onto classes outside their ` +
    `part (${soleProvider.size} that part's alone)`) +
  `: ${refViolations.length} unguarded reference(s), ${inheritViolations.length} inheritance edge(s)` +
  (membersSkipped ? '.' : `, ${memberViolations.length} unguarded reach(es) of an installed member.`));

if (inheritViolations.length) {
  console.error('\n[part-edges] FAIL -- core INHERITS from a part. This is not guardable: you cannot');
  console.error('conditionally extend a class or conditionally mix in a mixin. The PARTITION is wrong --');
  console.error('the base class / mixin is core material, so move it into core (or move the deriving');
  console.error('class into the part).');
  for (const v of inheritViolations) {
    console.error(`  ${v.rel}:${v.line}  ${v.from} -> ${v.name} (part '${v.owner}')`);
    console.error(`      ${v.text}`);
  }
}

if (refViolations.length) {
  console.error('\n[part-edges] FAIL -- a class present at boot names a part-owned class with no guard.');
  console.error("On an artifact that does not carry the part -- or, for a LAZY part, before anything has");
  console.error("fetched it -- this throws '<TheClass> is not defined' at the moment the code runs:");
  for (const v of refViolations) {
    console.error(`  ${v.rel}:${v.line}  ${v.from} -> ${v.name} (part '${v.owner}'${v.lazy ? ', LAZY' : ''})`);
    console.error(`      ${v.text}`);
  }
  console.error('\nFIX, for an EAGER part (present or absent, never late): guard the site --');
  console.error('  (new TheClass).doThing()  if TheClass?        # or a leading `return unless TheClass?`');
  console.error('FIX, for a LAZY part: a guard is WRONG there (it silently swallows the click). Await');
  console.error('the load instead:  world.parts.ensureLoaded("thePart").then -> …');
  console.error('Either way, if the reference is genuinely core-critical, the partition is wrong.');
}

if (memberViolations.length) {
  const CLAUSE = { a: 'a reference', b: 'dispatched by name', c: 'a super into it' };
  console.error('\n[part-edges] FAIL -- a source present at boot reaches a member only another PART installs.');
  console.error("That part's support class copies the member onto a class at boot (an `installOnto` edge in");
  console.error('src/boot/globalFunctions.coffee), so on an artifact that does not carry the part nothing');
  console.error('implements it -- whatever the receiver, for (a) and (b); above the class, for (c) -- and the');
  console.error('site throws, or a row dispatching it is dead:');
  for (const v of memberViolations) {
    const how = v.clause === 'c' ? `${v.cls}.${v.name} -> super` : v.clause === 'b' ? `"${v.name}"` : `.${v.name}`;
    console.error(`  ${v.rel}:${v.line}  ${v.from} -> ${how} (installed by part '${v.part}'; (${v.clause}) ${CLAUSE[v.clause]})`);
    console.error(`      ${v.text}`);
  }
  console.error('\nFIX: guard the site for that part, exactly as for one of its classes --');
  console.error('  @theMember?()        # or `if TheSupportClass?`, or a leading `return unless x.theMember?`');
  console.error('-- and for a `super`, end the walk in the class itself: without the part there is nothing above');
  console.error('it to call. If the member is product, it does not belong in the part: promote it.');
}

if (inheritViolations.length || refViolations.length || memberViolations.length) process.exit(1);
console.log(membersSkipped ? '[part-edges] OK -- every core reference into a part is guarded.' :
  '[part-edges] OK -- every core reference into a part, to a class or to a member it installs, is guarded.');
process.exit(0);

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
 */

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const REPO = path.resolve(__dirname, '..');
const PARTS_FILE = path.join(REPO, 'buildSystem/parts.json');

function fail(msg) { console.error('check-part-edges: ' + msg); process.exit(2); }

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

// strip trailing `# comment` while respecting quotes, and report whether code remains
const { codePartOf, guardedPartsPerLine } = require('./lib/part-edge-scan');

const refViolations = [];
const inheritViolations = [];

// EVERY file that is present at boot is in scope, not just core's. An EAGER part is in the artifact
// from the first frame exactly as core is, so `samples` naming a lazy `plots` class unguarded is the
// same defect as core doing it -- and it was invisible for as long as this gate looked only at core.
// A LAZY part is in scope too, against the parts it does NOT declare in `requires`.
const scanned = [...shippable].filter(rel => dirToPart.get(path.posix.normalize(path.posix.dirname(rel))));

for (const rel of scanned) {
  const owner = dirToPart.get(path.posix.normalize(path.posix.dirname(rel)));
  const abs = path.join(REPO, rel);
  let lines;
  try { lines = fs.readFileSync(abs, 'utf8').split('\n'); } catch (e) { continue; }
  const guards = guardedPartsPerLine(lines, partClassOwner, parts);
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
}

console.log(`[part-edges] scan done — ${scanned.length} source(s) present at boot or in a part vs ` +
  `${partClassOwner.size} part-owned class(es) in ${new Set(partClassOwner.values()).size} part(s): ` +
  `${refViolations.length} unguarded reference(s), ${inheritViolations.length} inheritance edge(s).`);

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

if (inheritViolations.length || refViolations.length) process.exit(1);
console.log('[part-edges] OK -- every core reference into a part is guarded.');
process.exit(0);

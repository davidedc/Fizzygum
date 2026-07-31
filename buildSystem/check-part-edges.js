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
 *      guard's own line. That one rule covers both shapes the tree actually uses:
 *        if Automator?                     |  if Automator? and
 *          @automator = new Automator      |      Automator.animationsPacingControl and
 *                                          |      Automator.state == Automator.PLAYING
 *      the guarded block, and the multi-line boolean continuation;
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
 * Scope: the CORE part's own .coffee files (from parts.json, via build.py --list-shippable to stay
 * consistent with how every other gate learns the file set).
 *
 * ⚠⚠ PART-TO-PART REFERENCES ARE NOT CHECKED HERE, AND NOTHING ELSE CHECKS THEM EITHER. This note
 * used to say they were "legitimate when the manifest declares the dependency"; that was never true.
 * parts.json has no `requires` field, the runtime manifest build.py emits carries exactly
 * {batches, eager, vendor, classes}, and PartsRegistry.ensureLoaded loads the one part it is given
 * ("and, when it grows one, whatever it requires" — future tense, still). What DOES express a
 * cross-part dependency is the DOOR: `whenAllLoaded ["maps", "plots"]` names both, so a reference
 * from part A into lazy part B is safe exactly when every door that pulls A in also names B. That
 * is a convention held up by comments, not by a gate — so when you add such an edge, say so at the
 * door (see samples/SampleDashboardApp.launch and demos/DemoMenus.createImageWdgt).
 * ⛔ A door naming two parts does NOT make cross-part INHERITANCE safe: ensureAllLoaded is a
 * Promise.all, so the two load concurrently with no ordering, and `class X extends Y` across that
 * boundary is a race. Only findLoadOrder inside a single part orders anything. An inheritance family
 * is therefore indivisible — which is why 'authoring' is one part rather than one per app.
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
function codePartOf(line) {
  let out = '';
  let quote = null;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (quote) {
      if (c === '\\') { i++; continue; }
      if (c === quote) quote = null;
      continue;                     // characters inside a string are not code identifiers here
    }
    if (c === '"' || c === "'") { quote = c; continue; }
    if (c === '#') break;           // rest of the line is a comment
    out += c;
  }
  return out;
}

const indentOf = (line) => line.length - line.replace(/^\s*/, '').length;

// Which PARTS are guarded on each line. Two sources, both per-part (see the header):
//   * an `X?` existence test, guarding its own line plus every deeper-indented line under it
//     (the guarded block AND the multi-line boolean continuation);
//   * a `return unless X?` bail-out, guarding the rest of the enclosing method.
// A logical line can span several physical ones: CoffeeScript continues it when the previous line
// ends with a binary/opening operator, and the continuation may be indented LESS than the opener
// (StringWdgt.toString does exactly that). So a continuation inherits its opener's guards outright,
// independently of indentation.
const CONTINUES = /(?:\b(?:and|or|not|is|isnt|then|else|unless|if|in|of)|&&|\|\||[,+\-*/%=<>?:.([{])\s*$/;

function guardedPartsPerLine(lines, ownerOfClass) {
  const perLine = lines.map(() => new Set());
  const openGuards = [];      // {indent, part} — active while we are deeper than indent
  let method = null;          // {indent, parts:Set} — a return-unless bail-out's scope
  let prevCodeLine = -1;      // last non-blank line, for continuation detection

  for (let i = 0; i < lines.length; i++) {
    const raw = lines[i];
    const ind = indentOf(raw);
    const blank = raw.trim() === '';
    const isContinuation = prevCodeLine >= 0 && CONTINUES.test(codePartOf(lines[prevCodeLine]));

    if (!blank && !isContinuation) {
      while (openGuards.length && ind <= openGuards[openGuards.length - 1].indent) openGuards.pop();
      if (method && ind <= method.indent) method = null;
    }

    // guards inherited from an enclosing `if X?` / continuation, and from a method bail-out
    for (const g of openGuards) perLine[i].add(g.part);
    if (method) for (const p of method.parts) perLine[i].add(p);
    // a continuation carries its opener's guards, whatever its indentation
    if (!blank && isContinuation) for (const p of perLine[prevCodeLine]) perLine[i].add(p);

    if (blank) continue;
    prevCodeLine = i;

    const m = /^(\s+)(?:@)?[\w$]+\s*:\s*(?:\(.*?\))?\s*[-=]>/.exec(raw);
    if (m) method = { indent: m[1].length, parts: new Set() };

    // `return unless X?` / `return if !X?` -> guards the rest of the method
    const bail = /^\s*return\b.*?\b([A-Z][\w$]*)\?/.exec(raw);
    if (bail && /\breturn\s+(?:unless|if\s*!)/.test(raw)) {
      const part = ownerOfClass.get(bail[1]);
      if (part && method) { method.parts.add(part); perLine[i].add(part); }
    }

    // any `X?` existence test on this line guards this line and everything nested under it
    const tests = raw.match(/\b[A-Z][\w$]*\?/g) || [];
    for (const t of tests) {
      const part = ownerOfClass.get(t.slice(0, -1));
      if (!part) continue;
      perLine[i].add(part);
      openGuards.push({ indent: ind, part });
    }
  }
  return perLine;
}

const refViolations = [];
const inheritViolations = [];

for (const rel of coreFiles) {
  const abs = path.join(REPO, rel);
  let lines;
  try { lines = fs.readFileSync(abs, 'utf8').split('\n'); } catch (e) { continue; }
  const guards = guardedPartsPerLine(lines, partClassOwner);

  for (let i = 0; i < lines.length; i++) {
    const code = codePartOf(lines[i]);
    if (!code.trim()) continue;
    for (const p of patterns) {
      if (!p.ref.test(code)) continue;
      if (p.inherit.test(code)) {
        inheritViolations.push({ rel, line: i + 1, name: p.name, owner: p.owner, text: lines[i].trim() });
        continue;
      }
      if (guards[i].has(p.owner)) continue;
      refViolations.push({ rel, line: i + 1, name: p.name, owner: p.owner, text: lines[i].trim() });
    }
  }
}

console.log(`[part-edges] scan done — ${coreFiles.length} core source(s) vs ` +
  `${partClassOwner.size} part-owned class(es) in ${new Set(partClassOwner.values()).size} part(s): ` +
  `${refViolations.length} unguarded reference(s), ${inheritViolations.length} inheritance edge(s).`);

if (inheritViolations.length) {
  console.error('\n[part-edges] FAIL -- core INHERITS from a part. This is not guardable: you cannot');
  console.error('conditionally extend a class or conditionally mix in a mixin. The PARTITION is wrong --');
  console.error('the base class / mixin is core material, so move it into core (or move the deriving');
  console.error('class into the part).');
  for (const v of inheritViolations) {
    console.error(`  ${v.rel}:${v.line}  core -> ${v.name} (part '${v.owner}')`);
    console.error(`      ${v.text}`);
  }
}

if (refViolations.length) {
  console.error('\n[part-edges] FAIL -- core names a part-owned class with no guard. On an artifact');
  console.error("that does not carry the part, this throws '<TheClass> is not defined' when the code runs:");
  for (const v of refViolations) {
    console.error(`  ${v.rel}:${v.line}  core -> ${v.name} (part '${v.owner}')`);
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

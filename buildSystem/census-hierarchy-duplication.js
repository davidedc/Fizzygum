#!/usr/bin/env node
'use strict';
/*
 * census-hierarchy-duplication.js — the HIERARCHY-AWARE duplication census: which overrides add
 * NOTHING to what they would inherit.
 *
 * TWO MODES, and the split is the point (docs/architecture/lint-and-static-checks.md §3b):
 *   (default)  ADVISORY: always exits 0 (2 only on operational error). It reports CANDIDATES for a
 *              human/LLM to triage. `fg critique` prints its summary lines.
 *   --gate     GATE (the build runs it): fails (exit 1, rule IDENTICAL_OVERRIDE) on the one subset of
 *              IDENTICAL-TO-INHERITED that is sound to judge — see "WHAT IS GATED, AND WHY ONLY THAT"
 *              below. Everything else stays advisory.
 * Its siblings:
 *   - check-*.js               — gates (exit 1 on violation)
 *   - census-public-private-calls.js — the public/private self-call census (this file's engine)
 *   - ./find_duplicated_code.sh (jscpd, exact clones) / ./find_similar_code.sh (jsinspect,
 *     structural clones) — those find TEXTUAL/STRUCTURAL twins but know nothing about inheritance,
 *     so they can never say "this override is REMOVABLE". That is exactly this census's gap to fill.
 *
 * Pharo ancestry (carried over 2026-07-15, docs/archive/lint-generic-rules-carryover-plan.md Phase 3):
 *   ReEquivalentSuperclassMethodsRule — an override equivalent to what it would inherit adds nothing
 *   ReJustSendsSuperRule             — an override that only forwards to super
 *
 * WHAT IT REPORTS (two categories):
 *   IDENTICAL-TO-INHERITED  own method whose signature and normalized body equal the NEAREST definition up
 *                           its parent chain — the nearest class defining the NAME, as a method or as a
 *                           field (a nearer field is what the class inherits, so it is no finding). Two
 *                           empty bodies count. Candidate: delete the override.
 *   JUST-SENDS-SUPER        method whose entire normalized body is the single token `super`.
 *
 *   ⚠ `super()` and `super arg…` are deliberately NOT flagged. In CoffeeScript BARE `super` forwards
 *   the caller's arguments, so a bare-super-only override is dispatch-equivalent to no override at
 *   all; but `super()` explicitly passes ZERO arguments, which differs from absence whenever the
 *   parent reads its arguments. Only the bare form is a removal candidate.
 *
 *   ⚠ A method is NOT defined by its body alone — the SIGNATURE (its parameter list, read to the balanced
 *   closing parenthesis, and its arrow, `->` or `=>`) is compared too, a signature this reading cannot take
 *   whole (a list running on to the next line) equals nothing, and a signature that does work on its own
 *   disqualifies a JUST-SENDS-SUPER finding. CoffeeScript's `(@color) ->` auto-assigns
 *   this.color and `(a = 5) ->` evaluates a default, so `constructor: (@color) -> super` is not
 *   equivalent to having no constructor however bare its body reads (real case:
 *   VideoPlayCreatorButtonWdgt — an early cut of this census called it removable, wrongly).
 *
 * ── WHAT IS GATED, AND WHY ONLY THAT (the severity policy — do not widen it) ────────────────────
 * Textual body equivalence is in general a CANDIDATE signal, not a proof of dispatch equivalence,
 * because a `super` binds to the class whose body it is written in (src/meta/Class.coffee's
 * `_rewriteSuperCalls` spells it `<ThatClass>.__super__.<member>`), so the same text in a subclass and
 * in its superclass calls different methods — an override whose body says `super` is a link in the
 * chain, and removing it drops that link. An unsound signal must never gate: a false gate-PASS bakes
 * regressions into byte-exact references.
 *   That objection reaches nothing else. `super` is the ONE construct whose meaning depends on the
 * class a body is written in: every member is compiled on its own (Class.coffee compiles
 * `assignment + member`), so a body has no class-body scope and a free name in it binds the same
 * thing wherever the text stands — save the member's OWN name, which the meta-system gives the function
 * (Class.coffee `_nameTheMemberFunction`), so a bare mention of it is that copy: two identical copies still
 * do the same, and only an identity test could tell them apart; `@` is the receiver, which is the same instance whether it found
 * the method on its own class or on a parent. So an override whose signature and body equal the
 * NEAREST inherited definition's, and whose body holds no `super` (read on the BARE view: a `super`
 * in a string or a comment is none), is the same code with nothing bound to its class — deleting it
 * cannot change what any call does. `--gate` fails on exactly that subset, at ZERO. (Deleting it does
 * change two things no call reaches: whether the class's prototype OWNS the member, and that a live
 * class-level edit of the parent's member now reaches the subclass — which is what inheriting means.)
 *   ⚠ The comparison is between SOURCE definitions: the class model is src/ and the harness, read as
 * the build ships them. A harness `*TestSupport.installOnto` copies members onto a core prototype at
 * boot, and would make a subclass's copy load-bearing if it replaced a member the target defines —
 * none does (each installs only members its target lacks), and an overwrite of that kind would be
 * its own defect.
 *   A copy kept ON PURPOSE — a member whose OWNERSHIP is read (the inspector's own-member rows; the
 * menu sweep derives its contributors from the prototypes owning addWidgetSpecificMenuEntries) —
 * says so on its header line or in the comment block directly above it:
 *     # identical-override-sanctioned: <why>
 * (a reason is required; a bare marker sanctions nothing). Every other finding — an identical body
 * that holds `super`, JUST-SENDS-SUPER — stays advisory and needs human verification before any
 * removal.
 *
 * ── CASE LAW — deliberate seams that must NOT be "cleaned up" ───────────────────────────────────
 * The 2026-07 duplication-refactor arc (ledger: duplication-report/triage-report.md, gitignored;
 * conventions: docs/tooling/duplicated-code-detection.md) established that the `_apply*`/`_commit*` corner
 * twins, the `*Base` override-bypass twins, and the mapRect twins are DELIBERATE same-class seams.
 * They are same-class SIBLINGS, not overrides, so they should not surface here at all — if one does,
 * classify it under the ledger's existing "deliberate seam" category rather than as removable.
 *
 * METHOD (heuristics, no type inference — the house style):
 *   - Class model (parent, methods, resolution order) is REUSED wholesale from
 *     census-public-private-calls.js via require() — see its runCensus() exports. Not copied: it is
 *     the subtle part, and two copies would drift.
 *   - Bodies are compared with their STRING LITERALS INTACT (two bodies differing only in a string
 *     are NOT duplicates), so this file cannot use the census's own string-STRIPPED bodyLines; it
 *     re-reads each source through lib/coffee-mask.js and takes its `code` view (comments blanked, strings
 *     kept).
 *   - Normalization: cut comments, drop blank lines, DEDENT to the body's own minimum indent (so two
 *     bodies indented by different amounts are comparable), collapse internal
 *     whitespace runs to one space. Relative indentation is PRESERVED — CoffeeScript is
 *     indentation-significant, so flattening it would equate different programs.
 *
 * USAGE (run from the Fizzygum/ repo root, like the gates):
 *   node ./buildSystem/census-hierarchy-duplication.js [--gate] [--json out.json] [--full] [--src=DIR] [--tests-repo=DIR]
 * It reads the compiled sources (lib/source-files.js compiledFiles: src/ and the tests repo's harness); the rails
 * read another src tree / tests repo (a copy carrying a plant). That --gate BITES — a plain identical override
 * fails, while one holding `super`, a sanctioned one and one with a different signature pass — is proven on every
 * build by census-hierarchy-duplication-selftest.js.
 * Exit codes: 0 = ran (--gate: clean) · 1 = --gate found an unsanctioned identical override · 2 = operational error.
 */

const fs = require('fs');
const { runCensus } = require('./census-public-private-calls.js');
const { coffeeMask, isCommentOnly } = require('./lib/coffee-mask');
const { rejectUnknownArgs } = require('./lib/cli-args');
const { compiledFiles, sourceRoots, sourceName, SOURCE_RAILS } = require('./lib/source-files');
const rules = require('./lib/gate-rules').forGate(__filename);

const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, [...SOURCE_RAILS, '--full', '--json', '--gate'], 'census-hierarchy-duplication');
const ROOTS = sourceRoots(ARGV, 'census-hierarchy-duplication');
const FULL = ARGV.includes('--full');
const GATE = ARGV.includes('--gate');
const jsonIdx = ARGV.indexOf('--json');
const JSON_OUT = jsonIdx >= 0 ? ARGV[jsonIdx + 1] : null;
// each compiled source by the name the class model gives its file (lib/source-files.js sourceName)
const FILE_OF = new Map(compiledFiles(ROOTS).map((f) => [sourceName(f, ROOTS), f]));

// ── body extraction ─────────────────────────────────────────────────────────────────────────────

// Every line of a file as lib/coffee-mask.js reads it, read once.
const maskedCache = new Map();
function maskedLinesOf(relFile) {
  let lines = maskedCache.get(relFile);
  if (!lines) {
    lines = coffeeMask(fs.readFileSync(FILE_OF.get(relFile), 'utf8'), relFile);
    maskedCache.set(relFile, lines);
  }
  return lines;
}

// Every line of a file with its comment blanked and its string content KEPT (lib/coffee-mask.js's code view).
const strippedCache = new Map();
function strippedLinesOf(relFile) {
  let lines = strippedCache.get(relFile);
  if (lines) return lines;
  lines = maskedLinesOf(relFile).map((line) => line.code);
  strippedCache.set(relFile, lines);
  return lines;
}

// Does the method's body hold a `super`? Read on the census's bodyLines, which are the BARE view (comments and every
// literal's contents blanked), so a `super` in a string or a comment is none. Any `super` word counts — a call, a
// bare forward, a property named so — which only ever keeps a finding advisory, never gates one wrongly.
const holdsSuper = (rec) => rec.bodyLines.some((b) => /\bsuper\b/.test(b.code));

// The reason of an `# identical-override-sanctioned: <why>` on the method's header line or in the comment block
// directly above it (contiguous comment-only lines), else undefined. A marker with no reason sanctions nothing.
const SANCTION = /identical-override-sanctioned:[ \t]*(\S.*)$/;
function sanctionOf(rec) {
  const masked = maskedLinesOf(rec.file);
  const reasonAt = (i) => SANCTION.exec(masked[i].comment || '')?.[1];
  const onHeader = reasonAt(rec.line - 1);
  if (onHeader) return onHeader;
  for (let i = rec.line - 2; i >= 0 && isCommentOnly(masked[i]); i--) {
    const above = reasonAt(i);
    if (above) return above;
  }
  return undefined;
}

const squeeze = (s) => s.trim().replace(/\s+/g, ' ');

// The method's SIGNATURE: { params, arrow } — its parameter list, normalized ('' when it takes none), and its
// arrow (`->` or `=>`) — or undefined when the header line does not hold the whole list (one that runs on to the
// next line, or a header this reading does not recognise). A method is not defined by its body alone: in
// CoffeeScript a signature can DO things. `(@color) ->` auto-assigns this.color, and `(a = 5) ->` evaluates a
// default — so `constructor: (@color) -> super` is NOT equivalent to having no constructor, however bare its body
// looks. (Real case: VideoPlayCreatorButtonWdgt, whose comment says it "keeps a constructor only to capture
// @color". An early cut of this census flagged it as removable — hence signatureOf, and hence the two uses below.)
// The list is read to its BALANCED closing parenthesis on the bare view (a parenthesis in a string is none), so a
// default holding a call (`(w = @topWdgtUnderPointer()) ->`) is read whole; its text is taken from the code view.
function signatureOf(rec) {
  const masked = maskedLinesOf(rec.file)[rec.line - 1];
  if (!masked) return undefined;
  const { bare, code } = masked;
  const head = /^\s*[A-Za-z_$][\w$]*\s*:\s*/.exec(bare);
  if (!head) return undefined;
  let at = head[0].length;
  let params = '';
  if (bare[at] === '(') {
    let depth = 0;
    let close = -1;
    for (let j = at; j < bare.length && close < 0; j++) {
      if (bare[j] === '(') depth++;
      else if (bare[j] === ')' && --depth === 0) close = j;
    }
    if (close < 0) return undefined;             // the list runs on past this line
    params = squeeze(code.slice(at + 1, close));
    at = close + 1;
  }
  const arrow = /^\s*([-=]>)/.exec(bare.slice(at));
  return arrow ? { params, arrow: arrow[1] } : undefined;
}
// two signatures are the same only when both are known and agree in their list and their arrow
const sameSignature = (a, b) => !!a && !!b && a.params === b.params && a.arrow === b.arrow;
// does the signature itself have an effect (auto-assign / default), making the method un-removable? An unknown
// signature is presumed to.
const signatureHasEffect = (sig) => !sig || /@/.test(sig.params) || /=/.test(sig.params);

// Every name a class DEFINES at class level, as a method or as a field (`  name: <anything>`, instance side; a
// class-side `@name:` is not one), read off its file's code: the nearest definition of a member is the nearest
// class defining the NAME, whatever it holds — a field between a class and an ancestor's method is what an
// instance of the class inherits, not the method.
const definedNamesCache = new Map();
function namesDefinedBy(info) {
  let names = definedNamesCache.get(info.name);
  if (!names) {
    names = new Set(info.methods.keys());
    for (const line of maskedLinesOf(info.file)) {
      if (line.continuesLiteral) continue;
      const key = /^ {2}([A-Za-z_$][\w$]*)\s*:(?!:)/.exec(line.bare);
      if (key) names.add(key[1]);
    }
    definedNamesCache.set(info.name, names);
  }
  return names;
}

// The method's body as comparable text. `rec` comes from the census: rec.line is the header's line,
// and any bodyLine whose n === rec.line is the INLINE remainder after the arrow (`foo: -> @bar()`).
// Inline and indented bodies normalize to the same text, which is correct — they are the same
// program.
function bodyTextOf(rec) {
  const src = strippedLinesOf(rec.file);
  const inline = [];
  const rest = [];
  for (const b of rec.bodyLines) {
    const line = src[b.n - 1];
    if (line === undefined) continue;
    if (b.n === rec.line) {
      // slice past the arrow. (indexOf('>') mirrors the census's own header handling; a `>` inside a
      // parameter default would fool it — vanishingly rare, and consistent with the engine.)
      const gt = line.indexOf('>');
      const tail = gt >= 0 ? line.slice(gt + 1) : '';
      if (tail.trim()) inline.push(squeeze(tail));
    } else if (line.trim()) {
      rest.push(line);
    }
  }
  let dedented = [];
  if (rest.length) {
    const min = Math.min(...rest.map((l) => l.length - l.trimStart().length));
    dedented = rest.map((l) => ' '.repeat((l.length - l.trimStart().length) - min) + squeeze(l));
  }
  return [...inline, ...dedented].join('\n');
}

// ── run ─────────────────────────────────────────────────────────────────────────────────────────
let out;
try {
  out = runCensus(ROOTS);
} catch (e) {
  console.error('[hierarchy-duplication] ERROR — ' + e.message);
  process.exit(2);
}
const { classInfo, chainOf } = out;

const bodyCache = new Map();
const bodyOf = (rec) => {
  const k = rec.cls + '.' + rec.name + ':' + rec.line;
  if (!bodyCache.has(k)) bodyCache.set(k, bodyTextOf(rec));
  return bodyCache.get(k);
};
const lineCount = (t) => (t ? t.split('\n').length : 0);

const identical = [];      // parent-chain overrides equal to what they'd inherit
const justSuper = [];      // body is the bare token `super`

for (const info of classInfo.values()) {
  const chain = chainOf(info.name);

  for (const [name, rec] of info.methods) {
    const body = bodyOf(rec);
    const sig = signatureOf(rec);

    // bare `super` AND a signature that does nothing on its own — see signatureHasEffect
    if (body === 'super' && !signatureHasEffect(sig)) {
      justSuper.push({ cls: info.name, name, at: `${rec.file}:${rec.line}`, sig: sig.params });
    }

    // nearest definition ABOVE this class (chain[0] is the class itself), in any form: a nearer FIELD of the same
    // name is what the class would inherit, so a method further up is no finding
    let inherited = null;
    for (let i = 1; i < chain.length && !inherited; i++) {
      if (namesDefinedBy(chain[i]).has(name)) inherited = chain[i].methods.get(name) || 'a field';
    }
    if (!inherited || inherited === 'a field') continue;
    if (bodyOf(inherited) !== body) continue;
    if (!sameSignature(signatureOf(inherited), sig)) continue;   // same body, different or unknown signature — NOT equivalent
    // (two EMPTY bodies are a finding too: an empty override of an empty definition is the same code)

    const row = {
      cls: info.name, name, at: `${rec.file}:${rec.line}`,
      from: inherited.cls, fromAt: `${inherited.file}:${inherited.line}`,
      lines: lineCount(body),
      holdsSuper: holdsSuper(rec), sanction: sanctionOf(rec),
    };
    identical.push(row);
  }
}

const bySize = (a, b) => b.lines - a.lines || (a.cls + a.name < b.cls + b.name ? -1 : 1);
identical.sort(bySize);
justSuper.sort((a, b) => (a.cls + a.name < b.cls + b.name ? -1 : 1));

// ── the gate (--gate): an identical override with no `super` in it, unsanctioned, fails ─────────
if (GATE) {
  const judged = identical.filter((r) => !r.holdsSuper);
  const offenders = judged.filter((r) => !r.sanction);
  const sanctioned = judged.length - offenders.length;
  if (offenders.length) {
    console.error('\n[hierarchy-duplication] FAIL -- an override identical to the definition it inherits, with no `super` in it:');
    for (const r of offenders) {
      console.error('  ' + rules.fired('IDENTICAL_OVERRIDE',
        `IDENTICAL_OVERRIDE ${r.at}: ${r.cls}.${r.name} == ${r.from}.${r.name}  [${r.fromAt}]`));
    }
    console.error('\nDelete the override: it is the same code with nothing bound to its class, so the inherited');
    console.error('definition already does what it does (a comment on it that describes the subclass moves to the');
    console.error('core it describes). If its prototype must OWN the member (a reader of ownership), keep it and say why');
    console.error('on or directly above its header: # identical-override-sanctioned: <why>');
    process.exit(1);
  }
  console.log(`[hierarchy-duplication] OK -- 0 overrides identical to what they inherit with no \`super\` in them ` +
              `(${sanctioned} sanctioned; ${identical.length - judged.length} holding \`super\` stay advisory).`);
  process.exit(0);
}

// ── report ──────────────────────────────────────────────────────────────────────────────────────
const trunc = (arr, n) => (FULL ? arr : arr.slice(0, n));

console.log('=== census-hierarchy-duplication ===');
console.log(`scanned ${classInfo.size} classes / ${out.allMethods.length} methods`);
console.log(`IDENTICAL-TO-INHERITED: ${identical.length}   JUST-SENDS-SUPER: ${justSuper.length}`);
console.log('\nADVISORY — this listing gates nothing (the build runs --gate, which judges only an identical override');
console.log('with no `super` in it). Every other finding is a CANDIDATE: `super` is meta-compiled');
console.log('(src/meta/Class.coffee), so textual equivalence is not dispatch equivalence. Verify by hand.');

console.log(`\n--- IDENTICAL-TO-INHERITED (${identical.length}) — candidate: delete the override ---`);
for (const r of trunc(identical, 40)) {
  console.log(`  ${r.at}: ${r.cls}.${r.name} == ${r.from}.${r.name} (${r.lines} line${r.lines === 1 ? '' : 's'})  [${r.fromAt}]`);
}
if (!FULL && identical.length > 40) console.log(`  … ${identical.length - 40} more (--full)`);

console.log(`\n--- JUST-SENDS-SUPER (${justSuper.length}) — bare \`super\` only (super()/super args NOT flagged) ---`);
for (const r of trunc(justSuper, 40)) console.log(`  ${r.at}: ${r.cls}.${r.name}`);
if (!FULL && justSuper.length > 40) console.log(`  … ${justSuper.length - 40} more (--full)`);

if (JSON_OUT) {
  fs.writeFileSync(JSON_OUT, JSON.stringify({ identical, justSuper }, null, 1));
  console.log('\n[hierarchy-duplication] JSON written to ' + JSON_OUT);
}
process.exit(0);

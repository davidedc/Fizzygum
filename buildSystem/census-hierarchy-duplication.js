#!/usr/bin/env node
'use strict';
/*
 * census-hierarchy-duplication.js — the HIERARCHY-AWARE duplication census: which overrides add
 * NOTHING to what they would inherit.
 *
 * ADVISORY, never a gate: always exits 0 (2 only on operational error). It reports CANDIDATES for a
 * human/LLM to triage — see "WHY THIS CAN NEVER BE A GATE" below. Its siblings:
 *   - check-*.js               — gates (exit 1 on violation)
 *   - census-public-private-calls.js — the public/private self-call census (this file's engine)
 *   - ./find_duplicated_code.sh (jscpd, exact clones) / ./find_similar_code.sh (jsinspect,
 *     structural clones) — those find TEXTUAL/STRUCTURAL twins but know nothing about inheritance,
 *     so they can never say "this override is REMOVABLE". That is exactly this census's gap to fill.
 *
 * Pharo ancestry (carried over 2026-07-15, docs/lint-generic-rules-carryover-plan.md Phase 3):
 *   ReEquivalentSuperclassMethodsRule — an override equivalent to what it would inherit adds nothing
 *   ReJustSendsSuperRule             — an override that only forwards to super
 *   ReLocalMethodsSameThanTraitRule  — a method identical to what the mixin already provides
 *
 * WHAT IT REPORTS (three categories):
 *   IDENTICAL-TO-INHERITED  own method whose normalized body equals the NEAREST definition up its
 *                           chain (parent chain). Candidate: delete the override.
 *   SHADOWS-MIXIN           same, but the nearest definition comes from an @augmentWith mixin. Kept
 *                           SEPARATE on purpose: which copy wins is a src/meta/Class.coffee detail,
 *                           so this census flags the collision and lets a human decide which side
 *                           should go — it does not claim the override is dead.
 *   JUST-SENDS-SUPER        method whose entire normalized body is the single token `super`.
 *
 *   ⚠ `super()` and `super arg…` are deliberately NOT flagged. In CoffeeScript BARE `super` forwards
 *   the caller's arguments, so a bare-super-only override is dispatch-equivalent to no override at
 *   all; but `super()` explicitly passes ZERO arguments, which differs from absence whenever the
 *   parent reads its arguments. Only the bare form is a removal candidate.
 *
 *   ⚠ A method is NOT defined by its body alone — the SIGNATURE is compared too, and a signature
 *   that does work on its own disqualifies a finding. CoffeeScript's `(@color) ->` auto-assigns
 *   this.color and `(a = 5) ->` evaluates a default, so `constructor: (@color) -> super` is not
 *   equivalent to having no constructor however bare its body reads (real case:
 *   VideoPlayCreatorButtonWdgt — an early cut of this census called it removable, wrongly).
 *
 * ── WHY THIS CAN NEVER BE A GATE (the severity policy — do not "promote" it) ────────────────────
 * Textual body equivalence is a CANDIDATE signal, never a proof of dispatch equivalence, because
 * `super` is META-COMPILED here: src/meta/Class.coffee (`_equivalentforSuper`) REWRITES every super
 * form when it compiles fragments in-browser, and a trailing space after a bare `super` silently
 * dropped forwarded arguments once (a real past bug — the reason buildSystem/check-trailing-
 * whitespace.js exists). Two textually-identical bodies can therefore dispatch differently. An
 * unsound signal must never gate: a false gate-PASS bakes regressions into byte-exact references.
 * Every finding below needs human verification before any removal.
 *
 * ── CASE LAW — deliberate seams that must NOT be "cleaned up" ───────────────────────────────────
 * The 2026-07 duplication-refactor arc (ledger: duplication-report/triage-report.md, gitignored;
 * conventions: docs/duplicated-code-detection.md) established that the `_apply*`/`_commit*` corner
 * twins, the `*Base` override-bypass twins, and the mapRect twins are DELIBERATE same-class seams.
 * They are same-class SIBLINGS, not overrides, so they should not surface here at all — if one does,
 * classify it under the ledger's existing "deliberate seam" category rather than as removable.
 *
 * METHOD (heuristics, no type inference — the house style):
 *   - Class model (parent, @augmentWith mixins, methods, resolution order) is REUSED wholesale from
 *     census-public-private-calls.js via require() — see its runCensus() exports. Not copied: it is
 *     the subtle part, and two copies would drift.
 *   - Bodies are compared with their STRING LITERALS INTACT (two bodies differing only in a string
 *     are NOT duplicates), so this file cannot use the census's own string-STRIPPED bodyLines; it
 *     re-reads each source and cuts comments with the census's exported maskLine (which LABELS
 *     strings rather than deleting them).
 *   - Normalization: cut comments, drop blank lines, DEDENT to the body's own minimum indent (so a
 *     4-space class method and an 8-space mixin-DSL method are comparable), collapse internal
 *     whitespace runs to one space. Relative indentation is PRESERVED — CoffeeScript is
 *     indentation-significant, so flattening it would equate different programs.
 *
 * USAGE (run from the Fizzygum/ repo root, like the gates):
 *   node ./buildSystem/census-hierarchy-duplication.js [--json out.json] [--full]
 * Exit codes: 0 = ran · 2 = operational error.
 */

const fs = require('fs');
const path = require('path');
const { runCensus, maskLine } = require('./census-public-private-calls.js');

const SRC = path.resolve(__dirname, '../src');
const FULL = process.argv.includes('--full');
const jsonIdx = process.argv.indexOf('--json');
const JSON_OUT = jsonIdx >= 0 ? process.argv[jsonIdx + 1] : null;

// ── body extraction ─────────────────────────────────────────────────────────────────────────────

// Cut comments from every line of a file while KEEPING string content, carrying multi-line string
// state from line 1 (so a heredoc opened earlier masks its body correctly).
const strippedCache = new Map();
function strippedLinesOf(relFile) {
  let lines = strippedCache.get(relFile);
  if (lines) return lines;
  const raw = fs.readFileSync(path.join(SRC, relFile), 'utf8').split('\n');
  let state = null;
  lines = raw.map((line) => {
    const r = maskLine(line, state);
    state = r.state;
    let out = '';
    for (let i = 0; i < line.length; i++) if (r.mask[i] !== 'cut') out += line[i];
    return out;
  });
  strippedCache.set(relFile, lines);
  return lines;
}

const squeeze = (s) => s.trim().replace(/\s+/g, ' ');

// The method's PARAMETER LIST, normalized ('' when it takes none). A method is not defined by its
// body alone: in CoffeeScript a signature can DO things. `(@color) ->` auto-assigns this.color, and
// `(a = 5) ->` evaluates a default — so `constructor: (@color) -> super` is NOT equivalent to having
// no constructor, however bare its body looks. (Real case: VideoPlayCreatorButtonWdgt, whose comment
// says it "keeps a constructor only to capture @color". An early cut of this census flagged it as
// removable — hence signatureOf, and hence the two uses below.)
const PARAMS = /^\s*[A-Za-z_$][\w$]*\s*:\s*(\(([^)]*)\))?\s*[-=]>/;
function signatureOf(rec) {
  const m = PARAMS.exec(strippedLinesOf(rec.file)[rec.line - 1] || '');
  return m && m[2] ? squeeze(m[2]) : '';
}
// does the signature itself have an effect (auto-assign / default), making the method un-removable?
const signatureHasEffect = (sig) => /@/.test(sig) || /=/.test(sig);

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
  out = runCensus();
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
const shadowsMixin = [];   // own def equal to a mixin-provided one
const justSuper = [];      // body is the bare token `super`

for (const info of classInfo.values()) {
  const chain = chainOf(info.name);
  // classes reachable through THIS class's @augmentWith mixins (each mixin's own chain included)
  const viaMixins = new Set();
  for (const mx of info.mixins) for (const m of chainOf(mx)) viaMixins.add(m.name);

  for (const [name, rec] of info.methods) {
    const body = bodyOf(rec);
    const sig = signatureOf(rec);

    // bare `super` AND a signature that does nothing on its own — see signatureHasEffect
    if (body === 'super' && !signatureHasEffect(sig)) {
      justSuper.push({ cls: info.name, name, at: `${rec.file}:${rec.line}`, sig });
    }

    // nearest definition ABOVE this class (chain[0] is the class itself)
    let inherited = null;
    for (let i = 1; i < chain.length; i++) {
      const r = chain[i].methods.get(name);
      if (r) { inherited = r; break; }
    }
    if (!inherited) continue;
    if (bodyOf(inherited) !== body) continue;
    if (signatureOf(inherited) !== sig) continue;   // same body, different signature — NOT equivalent
    if (!body) continue;   // two empty bodies — nothing to say

    const row = {
      cls: info.name, name, at: `${rec.file}:${rec.line}`,
      from: inherited.cls, fromAt: `${inherited.file}:${inherited.line}`,
      lines: lineCount(body),
    };
    (viaMixins.has(inherited.cls) ? shadowsMixin : identical).push(row);
  }
}

const bySize = (a, b) => b.lines - a.lines || (a.cls + a.name < b.cls + b.name ? -1 : 1);
identical.sort(bySize);
shadowsMixin.sort(bySize);
justSuper.sort((a, b) => (a.cls + a.name < b.cls + b.name ? -1 : 1));

// ── report ──────────────────────────────────────────────────────────────────────────────────────
const trunc = (arr, n) => (FULL ? arr : arr.slice(0, n));

console.log('=== census-hierarchy-duplication ===');
console.log(`scanned ${classInfo.size} classes / ${out.allMethods.length} methods`);
console.log(`IDENTICAL-TO-INHERITED: ${identical.length}   SHADOWS-MIXIN: ${shadowsMixin.length}   JUST-SENDS-SUPER: ${justSuper.length}`);
console.log('\nADVISORY — nothing here gates. Every finding is a CANDIDATE: `super` is meta-compiled');
console.log('(src/meta/Class.coffee), so textual equivalence is not dispatch equivalence. Verify by hand.');

console.log(`\n--- IDENTICAL-TO-INHERITED (${identical.length}) — candidate: delete the override ---`);
for (const r of trunc(identical, 40)) {
  console.log(`  ${r.at}: ${r.cls}.${r.name} == ${r.from}.${r.name} (${r.lines} line${r.lines === 1 ? '' : 's'})  [${r.fromAt}]`);
}
if (!FULL && identical.length > 40) console.log(`  … ${identical.length - 40} more (--full)`);

console.log(`\n--- SHADOWS-MIXIN (${shadowsMixin.length}) — own def identical to the mixin's; decide which copy goes ---`);
for (const r of trunc(shadowsMixin, 40)) {
  console.log(`  ${r.at}: ${r.cls}.${r.name} == mixin ${r.from}.${r.name} (${r.lines} line${r.lines === 1 ? '' : 's'})  [${r.fromAt}]`);
}
if (!FULL && shadowsMixin.length > 40) console.log(`  … ${shadowsMixin.length - 40} more (--full)`);

console.log(`\n--- JUST-SENDS-SUPER (${justSuper.length}) — bare \`super\` only (super()/super args NOT flagged) ---`);
for (const r of trunc(justSuper, 40)) console.log(`  ${r.at}: ${r.cls}.${r.name}`);
if (!FULL && justSuper.length > 40) console.log(`  … ${justSuper.length - 40} more (--full)`);

if (JSON_OUT) {
  fs.writeFileSync(JSON_OUT, JSON.stringify({ identical, shadowsMixin, justSuper }, null, 1));
  console.log('\n[hierarchy-duplication] JSON written to ' + JSON_OUT);
}
process.exit(0);

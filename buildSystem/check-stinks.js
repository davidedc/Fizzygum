#!/usr/bin/env node
// check-stinks.js — build gate for "STINKS": code smells we are driving to zero, each RATCHETED at
// a baseline count (mirrors buildSystem/check-dead-methods.js, which ratchets dead code via an
// allowlist; and check-layering.js, which fails on any violation).
//
// Each stink carries a `baseline` — the max occurrences currently tolerated. The build FAILS when a
// stink EXCEEDS its baseline (a regression). When a stink drops BELOW its baseline you have driven
// it down: tighten the baseline in THIS file to lock the gain in (the check prints a reminder). A
// stink at baseline 0 is a HARD rule — any occurrence fails the build. There is no separate
// allowlist file: the baseline lives inline next to the rule, since a smell is a count, not a set of
// named methods.
//
// Add a new {id, baseline, why, re} to STINKS below to ratchet the next smell. `why` is not
// decoration — it is what a future reader gets INSTEAD of the arguing; write it for someone who
// does not already agree.
//
// Scope: src/**/*.coffee only (NOT the sibling test harness) — a stink is a statement about the
// SHIPPED framework's idiom. Per-LINE regex over `#`-comment-stripped lines; there is no multi-line
// matcher (an empty-catch stink would need one — plan §8.9).
//
// A stink may instead declare `scope: 'comments'` to match the COMMENT part of each line (from the
// first `#` onward) rather than the code part — the comment-hygiene ratchets (2026-07-17 comments
// cleanup) use this: comments must state present-tense constraints, not narrate history or carry
// meta-edits/debug residue (history's home is docs/archive/ — see docs/README.md filing rules).
// NB the naive `#` split means a `#` inside a string counts as a comment start here; accepted for
// the same measures-regression-not-absolutes reason as above.
//
// (Historical: the original settle-batch-with-core stink was retired when its target,
// _settleLayoutsAfterBatch, was deleted, leaving the table empty until the 2026-07-15 seeding.)

const fs = require('fs');
const path = require('path');

const SRC = path.resolve(__dirname, '../src');

// Seeded 2026-07-15 (docs/archive/lint-generic-rules-carryover-plan.md Phase 2), carrying over the generic
// cruft/idiom rules from Pharo's SmallLint/Renraku catalogue. Every baseline below was MEASURED by
// this engine on the day (never estimated) and every stink was spot-checked against its real hits.
// These are RATCHETS, not verdicts: each records today's count so the number can only fall. Driving
// any of them down is a FUTURE arc — the seeding arc deliberately changed no src.
//
// NB the counts are the ENGINE's, and stripComment (below) is a naive `#` cut that does NOT mask
// STRINGS — so e.g. undefined-literal counts `typeof x is 'undefined'`. That is accepted: a ratchet
// measures REGRESSION, not an absolute. (Masking upgrade = plan §8.8 backlog.)
const STINKS = [
  { id: 'debugger-statement', baseline: 33,   // Pharo: ReCodeCruftLeftInMethodsRule; tightened 36->33 on 2026-07-30 (banking a gain already landed; fg critique surfaced it)
    why: 'a debugger statement is left-in debug cruft; it hard-stops execution whenever devtools are open',
    re: /^\s*debugger\b/ },
  // `undefined-literal` (baseline 83) was DELETED on 2026-08-13: it enforced `nil` OVER `undefined`,
  // and the `nil` global it protected has been retired, so the rule now polices the opposite of the
  // convention. `nil-literal` is its replacement — same intent, inverted direction.
  { id: 'nil-literal', baseline: 0,   // HARD: `nil` no longer exists; a reference to it is a ReferenceError waiting to happen
    why: "the `nil = undefined` global is RETIRED — `undefined` is the codebase's one absence value, spelled the way the language spells it. `nil` was an alias for a primitive that cost a writable global, a boot-order dependency and a lint rule, and had leaked into the reflective layer as emitted source",
    re: /\bnil\b/ },
  { id: 'null-literal', baseline: 8,   // tightened 9->8 on 2026-08-13 (the DemoMenus stack-panel `null`s were a live CS2 default-param bug)
    why: "the codebase uses `undefined` as its ONE absence value, never `null` — the JS-interop sites (JSON.stringify's arg, DOM `onload = null`) are the tolerated tail",
    re: /\bnull\b/ },
  { id: 'wall-clock', baseline: 19,
    why: 'Date.now()/new Date() in framework code breaks event-stream determinism (Fizzygum-tests/DETERMINISM.md; multi-click recognition keys off EVENT timestamps, never the wall clock)',
    re: /\b(Date\.now\s*\(|new Date\s*\()/ },
  { id: 'timer', baseline: 4,   // raised 3->4 on 2026-08-04: SourceCompileScheduler._ensurePumpScheduled pumps the compile-at-boot ingest, which runs only while NO world exists (same nature as the waitNextJSEventLoopCycle timer beside it) — bug-class B needs a live suite world to bite
    why: 'setTimeout/setInterval diverge at dpr2 under parallel load (DETERMINISM.md bug-class B: heavy cycles starve timers); the cycle/step machinery is the sanctioned clock',
    re: /\b(setTimeout|setInterval)\s*\(/ },
  { id: 'math-random', baseline: 5,
    why: 'Math.random in render/layout/input code breaks byte-exact screenshot determinism',
    re: /\bMath\.random\b/ },
  { id: 'instanceof-type-test', baseline: 87,   // Pharo: ReBadMessageRule (isKindOf:); tightened 105->97 (2026-07-17); 97->95 (2026-07-18, DividerWdgt.isDivider role query retired 2 `instanceof DividerWdgt` in removeConsecutiveLines); 95->93 (2026-07-30, banking a gain already landed; fg critique surfaced it); 93->88 (2026-08-04, layout spec-family arc: the enum dispatch + 5 spec-class instanceofs became capability queries); 88->87 (2026-08-09, banking a gain already landed; surfaced by the comments-audit stink run)
    why: 'the type-test-elimination campaign drove instanceof down; this locks the tail against regrowth — prefer polymorphism',
    re: /\binstanceof\b/ },
  { id: 'positional-hole', baseline: 51,   // seeded 2026-08-15 at THIS engine's own count; target 0 (docs/plans/constructor-parameter-conformance-plan.md drives it down family by family)
    why: 'a call punching `undefined` through to reach a later argument PROVES the skipped parameter is configuration rather than identity — no single order can serve callers wanting disjoint tails. The remedy is a trailing `opts = {}` object (or, for an exempt value class, a reorder): docs/architecture/constructor-and-parameter-conventions.md R3',
    re: /\bundefined\b\s*,\s*\bundefined\b/ },
  // Comment-hygiene ratchets (2026-07-17 comments cleanup; baselines measured post-cleanup).
  { id: 'comment-meta-edit', baseline: 0, scope: 'comments',
    why: 'a comment arguing with itself ("the below is actually correct", "to be clear") is process residue — state the surviving constraint once, plainly',
    re: /\b(the (below|above) is|is actually (correct|right|fine|wrong)|to be clear,)\b/i },
  { id: 'comment-narration', baseline: 103, scope: 'comments',   // tightened 105->104 on 2026-08-04 (comments-audit sweep removed one; locking the gain in); 104->103 on 2026-08-15 (MenuItemSpec's header stopped narrating what its constructor replaced when that constructor changed again)
    why: 'history narration ("used to", "previously", "no longer", "in the old model") belongs in docs/archive/ with a pointer, not inline — a comment states what IS',
    re: /\b(used to\b|previously\b|no longer\b|in the old (model|way|code)\b)/i },
  { id: 'commented-out-debug', baseline: 0, scope: 'comments',
    why: 'commented-out alert/debugger/console.log is dead debug cruft — delete it; git remembers',
    re: /^#\s*(alert\s*\(|debugger\b|console\.log\s*[\('"])/ },
  { id: 'comment-past-receipt', baseline: 0, scope: 'comments',   // seeded at 33 and swept to ZERO the same day (2026-08-09) -- now a HARD rule; the sweep's translation idiom is "instead of <old expr>" (present-tense design statement, old expression kept as the contract spec)
    why: 'a "was <old code>" conversion receipt narrates history — state the surviving present-tense contract (what the predicate answers, or why this spelling) and let docs/archive/ keep the before-picture. EXCEPTION judged per-site at sweep time: an old expression that documents COMPOUND semantics the new form must preserve gets TRANSLATED into a present-tense contract, not deleted.',
    re: /\b(was|were) `|\bthis once was\b|\bformerly\b|\brenamed from\b/i },
];

function walk(dir, acc) {
  if (!fs.existsSync(dir)) return acc;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (e.name.endsWith('.coffee')) acc.push(p);
  }
  return acc;
}
function stripComment(line) { const i = line.indexOf('#'); return i < 0 ? line : line.slice(0, i); }
function commentPart(line) { const i = line.indexOf('#'); return i < 0 ? null : line.slice(i); }

// --list <stink-id>: print every site of ONE stink and exit — a sweep enumerator, not a gate
// (the comments-side twin of check-doc-narration's --full). Reached as `fg stinks --list <id>`.
const listIdx = process.argv.indexOf('--list');
const listId = listIdx >= 0 ? process.argv[listIdx + 1] : null;
if (listIdx >= 0 && !STINKS.some(s => s.id === listId)) {
  console.error(`[stinks] unknown stink id '${listId}' — known: ${STINKS.map(s => s.id).join(', ')}`);
  process.exit(2);
}

const files = walk(SRC, []);
let over = 0;        // total occurrences ABOVE baseline (a build failure)
let ratchetable = 0; // stinks now BELOW baseline (a chance to tighten)
for (const stink of STINKS) {
  if (listId && stink.id !== listId) continue;
  const baseline = stink.baseline || 0;
  const hits = [];
  for (const p of files) {
    fs.readFileSync(p, 'utf8').split('\n').forEach((line, i) => {
      const subject = stink.scope === 'comments' ? commentPart(line) : stripComment(line);
      if (subject !== null && stink.re.test(subject)) hits.push(`${path.relative(SRC, p)}:${i + 1}: ${line.trim()}`);
    });
  }
  const n = hits.length;
  if (listId) {
    console.log(`[stinks] ${stink.id}: ${n} site(s) (baseline ${baseline})`);
    for (const h of hits) console.log(`    ${h}`);
    process.exit(0);
  }
  const tag = n > baseline ? 'FAIL' : n < baseline ? 'UNDER' : 'OK';
  console.log(`[stinks] ${stink.id}: ${n} site(s) (baseline ${baseline}) -- ${tag}`);
  if (n > baseline) {
    over += n - baseline;
    console.error(`    ${stink.why}`);
    for (const h of hits) console.error(`    ${h}`);
  } else if (n < baseline) {
    ratchetable++;
  }
}

if (ratchetable) {
  console.log(`[stinks] NOTE -- ${ratchetable} stink(s) now BELOW baseline; tighten its baseline in buildSystem/check-stinks.js to lock the gain in.`);
}

if (over) {
  console.error(`\n[stinks] FAIL -- ${over} occurrence(s) over baseline. Either fix the smell (preferred) or, if genuinely intentional, raise that stink's baseline in buildSystem/check-stinks.js with a one-line reason.`);
  process.exit(1);
}

console.log(`[stinks] OK -- all stinks within baseline.`);
process.exit(0);

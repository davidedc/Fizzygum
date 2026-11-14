#!/usr/bin/env node
// check-doc-narration.js — the docs-side twin of the `comment-narration` stink.
//
// WHY THIS EXISTS. `docs/README.md` files every doc by what it IS, and the buckets carry a
// TENSE. `architecture/` is "how a subsystem works NOW — no history, no plans"; filing rule 3
// says durable residue lands there "present tense, no changelog prose. The plan keeps the
// history; the architecture doc keeps only the current truth." `tooling/` is present-tense too.
// Nothing enforced that, so changelog prose accreted there arc after arc — a doc ends up
// explaining a live mechanism by naming the dead one it replaced, and eventually contradicts
// itself (one section stating a change landed while another still proposes it).
//
// The same words are already gated in SOURCE COMMENTS by the `comment-narration` stink
// (check-stinks.js). This applies that rule to the present-tense doc buckets.
//
// SCOPE — deliberately NOT every bucket:
//   CHECKED   architecture/ tooling/     present tense by definition
//   CHECKED   BACKLOG.md                 for ONE thing: a closed item (a `- [x]` task item at any depth, any bullet,
//                                        outside a fenced block). The file holds OPEN items only — filing rule 2
//                                        moves a closed item, verbatim, into the ledger of the plan that closed it —
//                                        so a `- [x]` there is an item that never moved. A hard zero with no baseline
//                                        (BACKLOG_CLOSED_ITEM). Its prose is NOT judged for narration: an open item's
//                                        "found 2026-10-23" is provenance.
//   CHECKED   the two INSTRUCTION FILES  `Fizzygum/CLAUDE.md` and `Fizzygum-tests/CLAUDE.md`, for ONE thing: their
//                                        size. A session loads them before any work, and again after every compaction,
//                                        so each has a byte CEILING (INSTRUCTION_FILE_OVER_CEILING), recorded in the
//                                        baseline file beside the narration counts. Such a file keeps routing, the
//                                        commands, the rules that change what a reader does next, and one line per rig
//                                        pointing at its header; mechanism, history, measurements and case law live in
//                                        the rig's header or the architecture doc that owns the subsystem. Their prose
//                                        is not judged for narration.
//   SKIPPED   specs/                     a spec states what the product must do, and its
//                                        landing/change statements are load-bearing (owner
//                                        direction 2026-08-09)
//   SKIPPED   plans/ archive/ measurements/ explainers/prompts
//                                        chronological BY DESIGN — archive is immutable past
//                                        tense, plans are future tense, measurements are dated
//                                        snapshots. Narration there is correct, not a defect.
//
// Provenance stamps are NOT narration: "verified against src/ 2026-07-27" tells a reader how
// stale the verification is, which is useful and dateable. Narration is telling the story of
// how the code got here.
//
// THE NARRATION RULES ARE A RATCHET, not a zero-baseline gate — same shape as `check-stinks.js`
// (BACKLOG_CLOSED_ITEM is a hard zero: SCOPE above). The buckets carry pre-existing debt (mostly
// in the two gate-documentation docs, where a ban is explained by narrating what was removed),
// and rewriting all of it at once risks damaging real content.
// So: a per-file baseline in `check-doc-narration-baseline.json` (its `narration` section), and the check FAILS when any
// file's count RISES or a new file starts narrating. Accretion stops today; the debt burns down
// deliberately. Lower a number whenever you clean a doc — `--write-baseline` re-records.
//
// If this fires, either state the current fact without the history, or move the history to the
// plan/archive doc that owns it. `<!-- narration-ok: reason -->` on the line is the escape hatch,
// for the rare line that must QUOTE the narration words (e.g. the stink's own definition).

const fs = require('fs');
const path = require('path');
const { rejectUnknownArgs, rejectPositionalArgs, dirArg } = require('./lib/cli-args');
const rules = require('./lib/gate-rules').forGate(__filename);

// [--umbrella=DIR] reads another umbrella — `DIR/Fizzygum/docs` and the instruction files under `DIR` (a planted one: the
// bite-proof's input, check-doc-narration-selftest.js, which proves every rule below BITES). It never writes the real
// baseline from another tree.
const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, ['--full', '--write-baseline', '--umbrella='], 'doc-narration');
rejectPositionalArgs(ARGV, 'doc-narration', 'an umbrella is named with --umbrella=DIR');
if (ARGV.includes('--write-baseline') && ARGV.some((a) => a.startsWith('--umbrella='))) {
  console.error('[doc-narration] ERROR — --write-baseline writes the real baseline: it never reads another umbrella');
  process.exit(2);
}
const UMBRELLA = dirArg(ARGV, '--umbrella=', path.join(__dirname, '..', '..'), 'doc-narration');
const DOCS = path.join(UMBRELLA, 'Fizzygum', 'docs');
const BUCKETS = ['architecture', 'tooling'];
// the instruction files a session loads, each held to its byte ceiling (header, SCOPE)
const INSTRUCTION_FILES = ['Fizzygum/CLAUDE.md', 'Fizzygum-tests/CLAUDE.md'];

// Each rule is high-precision on purpose: a gate with a zero baseline only stays credible if it
// does not cry wolf. Ambiguous phrasings ("no longer compiles", "the old value") are deliberately
// NOT matched — they read as present-tense conditionals far more often than as narration.
// [regex, label, rule id] — the id is what a failing run names (lib/gate-rules.js)
const RULES = [
  // "used to" only — NOT a bare "use to", which is ordinary instruction ("use to bisect a bug").
  [/\bused to\b/i,                                 'used to', 'USED_TO'],
  [/\blong said\b/i,                               'long said', 'LONG_SAID'],
  [/\bwas rewor(?:ded|ked)\b/i,                    'was reworded', 'WAS_REWORDED'],
  [/\b(?:was|were|been)\s+(?:deleted|removed|retired|renamed|replaced by|converted (?:from|to))\b/i,
                                                   'past-tense change narration', 'PAST_TENSE_CHANGE'],
  [/\bformerly\b/i,                                'formerly', 'FORMERLY'],
  [/\bsince (?:hardened|deleted|removed|retired)\b/i, 'since <past participle>', 'SINCE_PARTICIPLE'],
  [/\bExecuted\s+20\d\d/i,                         'Executed <date>', 'EXECUTED_DATE'],
  [/\b(?:fixed|landed|added|changed|renamed|deleted|retired)\s+(?:on\s+)?20\d\d-\d\d-\d\d/i,
                                                   '<verb> <date>', 'VERB_DATE'],
  [/\b(?:until|since|as of)\s+20\d\d-\d\d-\d\d/i,  'until/since <date>', 'UNTIL_SINCE_DATE'],
  [/\bin (?:January|February|March|April|May|June|July|August|September|October|November|December)\s+20\d\d\b/i,
                                                   'in <Month> <year>', 'IN_MONTH_YEAR'],
  // the Thing is a capitalised word or inline code — and inline code is stripped before the rules read a line, so
  // `the old-\`Foo\`` reaches here as `the old- `
  [/\bthe (?:then|old)-(?:[A-Z]|\s|$)/,             'the then-/old-<Thing>', 'THE_THEN_OLD_THING'],
];
rules.declare(RULES.map((r) => r[2]));

// A provenance stamp dates the VERIFICATION, not a change. Legitimate; skip the line.
const STAMP = /\b(?:verified|re-verified|measured|snapshot(?:ted)?|stamped|as measured)\b/i;

// Strip fenced blocks and inline code so file paths (docs/archive/foo-2026-08-04.md), commit
// SHAs and code samples cannot trip a prose rule.
function proseLines(text) {
  const out = [];
  let fenced = false;
  text.split('\n').forEach((line, i) => {
    if (/^\s*```/.test(line)) { fenced = !fenced; return; }
    if (fenced) return;
    out.push([i + 1, line.replace(/`[^`]*`/g, '')]);
  });
  return out;
}

// An explicit, reason-bearing escape hatch for a line that must QUOTE the narration words.
const ALLOW = /<!--\s*narration-ok:/i;

const BASELINE_PATH = path.join(__dirname, 'check-doc-narration-baseline.json');
const write = process.argv.includes('--write-baseline');
const verbose = process.argv.includes('--full') || write;

const counts = {};
const hits = [];
const hitsOf = {};   // rel -> [{ id, line }]
let scanned = 0;
for (const bucket of BUCKETS) {
  const dir = path.join(DOCS, bucket);
  if (!fs.existsSync(dir)) continue;
  for (const name of fs.readdirSync(dir).filter(f => f.endsWith('.md')).sort()) {
    const rel = `docs/${bucket}/${name}`;
    scanned++;
    for (const [lineNo, line] of proseLines(fs.readFileSync(path.join(dir, name), 'utf8'))) {
      if (STAMP.test(line) || ALLOW.test(line)) continue;
      for (const [re, label, id] of RULES) {
        if (re.test(line)) {
          counts[rel] = (counts[rel] || 0) + 1;
          const hit = `  ${rel}:${lineNo}  [${label}]  …${line.trim().slice(0, 110)}`;
          hits.push(hit);
          (hitsOf[rel] = hitsOf[rel] || []).push({ id, line: hit });
          break;
        }
      }
    }
  }
}
const total = Object.values(counts).reduce((a, b) => a + b, 0);
// a run that read no doc checked nothing (a wrong root, a renamed bucket): no pass
if (!scanned) { console.error(`[doc-narration] ERROR — no .md doc under ${BUCKETS.map((b) => path.join(DOCS, b)).join(' or ')} — a run that read nothing is no pass`); process.exit(2); }

// the instruction files' sizes; one that is missing is one this run could not hold to its ceiling: no pass
const bytes = {};
for (const rel of INSTRUCTION_FILES) {
  const p = path.join(UMBRELLA, rel);
  if (!fs.existsSync(p)) { console.error(`[doc-narration] ERROR — no ${p}: a run that cannot read an instruction file checked nothing there — no pass`); process.exit(2); }
  bytes[rel] = fs.statSync(p).size;
}

if (write) {
  fs.writeFileSync(BASELINE_PATH, JSON.stringify({ narration: counts, instructionBytes: bytes }, null, 2) + '\n');
  console.log(hits.join('\n'));
  console.log(`\nbaseline written: ${total} line(s) across ${Object.keys(counts).length} file(s); ceilings ` +
    INSTRUCTION_FILES.map((f) => `${f} ${bytes[f]} bytes`).join(', ') + '.');
  process.exit(0);
}

// BACKLOG.md's closed items (header, SCOPE). An index it cannot read is one this run checked nothing in: no pass.
const BACKLOG_PATH = path.join(DOCS, 'BACKLOG.md');
if (!fs.existsSync(BACKLOG_PATH)) { console.error(`[doc-narration] ERROR — no ${BACKLOG_PATH}: a run that cannot read the open-items index checked nothing there — no pass`); process.exit(2); }
// A task-list item at any depth, any bullet (`-` `*` `+` `1.` `1)`), inside a quote too; a fenced block is skipped.
const TASK_ITEM = /^\s*(?:>\s*)*(?:[-*+]|\d+[.)])\s+\[([ xX])\](?=\s|$)/;
const closedItems = [];
let openItems = 0;
for (const [lineNo, line] of proseLines(fs.readFileSync(BACKLOG_PATH, 'utf8'))) {
  const m = line.match(TASK_ITEM);
  if (!m) continue;
  if (m[1] === ' ') openItems++;
  else closedItems.push(`  docs/BACKLOG.md:${lineNo}  [closed item]  …${line.trim().slice(0, 110)}`);
}

const baselineFile = fs.existsSync(BASELINE_PATH)
  ? JSON.parse(fs.readFileSync(BASELINE_PATH, 'utf8')) : {};
const baseline = baselineFile.narration || {};
const baseTotal = Object.values(baseline).reduce((a, b) => a + b, 0);

// each instruction file against its ceiling; a file with none recorded is one this run cannot judge: no pass
const ceilings = baselineFile.instructionBytes || {};
const over = [];
for (const rel of INSTRUCTION_FILES) {
  if (!Number.isInteger(ceilings[rel])) {
    console.error(`[doc-narration] ERROR — no byte ceiling for ${rel} in ${BASELINE_PATH}: record one with --write-baseline — no pass`);
    process.exit(2);
  }
  if (bytes[rel] > ceilings[rel]) over.push(`  ${rel}: ${bytes[rel]} bytes > ceiling ${ceilings[rel]}`);
}

const risen = [], improved = [];
for (const [f, n] of Object.entries(counts)) {
  const b = baseline[f] || 0;
  if (n > b) risen.push(`  ${f}: ${b} -> ${n}`);
}
for (const [f, b] of Object.entries(baseline)) {
  const n = counts[f] || 0;
  if (n < b) improved.push(`  ${f}: ${b} -> ${n}`);
}

if (verbose && hits.length) console.log(hits.join('\n') + '\n');

if (closedItems.length) {
  console.log(`BACKLOG HOLDS CLOSED ITEMS — ${closedItems.length} line(s):`);
  for (const line of closedItems) console.log(rules.fired('BACKLOG_CLOSED_ITEM', line));
  console.log('\ndocs/BACKLOG.md holds OPEN items only (docs/README.md filing rule 2): move each closed item, verbatim,');
  console.log('into the trailing `## BACKLOG ledger` section of the plan that closed it.');
  if (risen.length) console.log('');
}
if (risen.length) {
  console.log(`DOC-NARRATION ROSE — ${scanned} docs scanned, ${total} line(s) vs baseline ${baseTotal}:`);
  console.log(risen.join('\n'));
  // every narration line of a file whose count rose, each naming the rule it breaks
  for (const r of risen) for (const h of hitsOf[r.trim().split(':')[0]] || []) console.log(rules.fired(h.id, h.line));
  console.log('\nThese buckets are PRESENT TENSE (docs/README.md filing rule 3): state the current');
  console.log('fact without the history, or move the history to the plan/archive doc that owns it.');
  console.log('specs/, plans/, archive/ and measurements/ are chronological by design, not scanned.');
  console.log('Run with --full to list every line.');
}
if (over.length) {
  if (closedItems.length || risen.length) console.log('');
  console.log(`INSTRUCTION FILE OVER ITS CEILING — ${over.length} file(s):`);
  for (const line of over) console.log(rules.fired('INSTRUCTION_FILE_OVER_CEILING', line));
  console.log('\nAn instruction file keeps routing, the commands, the rules that change what a reader does next, and one');
  console.log("line per rig pointing at its header; mechanism, history, measurements and case law go to the rig's header");
  console.log('or the architecture doc that owns them (docs/architecture/lint-and-static-checks.md §3b-docs). A rule a reader');
  console.log('must meet before any work may raise the ceiling: `--write-baseline`, in the same commit.');
}
if (closedItems.length || risen.length || over.length) process.exit(1);

console.log(`OK — ${scanned} docs in ${BUCKETS.join('/')}; ${total} narration line(s), baseline ${baseTotal}; ` +
  `BACKLOG.md ${openItems} open item(s), 0 closed; ` +
  INSTRUCTION_FILES.map((f) => `${f} ${bytes[f]} of ${ceilings[f]} bytes`).join(', ') + '.');
for (const rel of INSTRUCTION_FILES) if (bytes[rel] < ceilings[rel]) improved.push(`  ${rel}: ceiling ${ceilings[rel]} -> ${bytes[rel]} bytes`);
if (improved.length) {
  console.log('IMPROVED — bank it with `node buildSystem/check-doc-narration.js --write-baseline`:');
  console.log(improved.join('\n'));
}
process.exit(0);

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
//   CHECKED   BACKLOG.md                 for TWO things: a closed item (a `- [x]` task item at any depth, any bullet,
//                                        outside a fenced block). The file holds OPEN items only — filing rule 2
//                                        moves a closed item, verbatim, into the ledger of the plan that closed it —
//                                        so a `- [x]` there is an item that never moved. A hard zero with no baseline
//                                        (BACKLOG_CLOSED_ITEM). And an open item's LENGTH (its task line and every
//                                        line Markdown renders as part of it — indented deeper, after a blank line
//                                        too; a fenced block inside it; a quoted item's quoted lines; a lazy
//                                        continuation — whitespace collapsed): the file is an INDEX,
//                                        each item what is wrong or to do, its reach or severity and where its detail
//                                        lives, so an item over the CEILING the baseline file records fails
//                                        (BACKLOG_ITEM_TOO_LONG) — measured on the raw text, inline code included;
//                                        `--write-baseline` records the longest open item, and refuses one over
//                                        BACKLOG_ITEM_HARD_MAX. Its prose is NOT judged for narration: an open
//                                        item's "found 2026-10-23" is provenance.
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
// bite-proof's input, check-doc-narration-selftest.js, which proves every rule below BITES). [--baseline=FILE] reads,
// and --write-baseline writes, another baseline file: the bite-proof's rail for the missing-ceiling and over-400
// refusals. It never writes the REAL baseline from another tree.
const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, ['--full', '--write-baseline', '--umbrella=', '--baseline='], 'doc-narration');
rejectPositionalArgs(ARGV, 'doc-narration', 'an umbrella is named with --umbrella=DIR');
const BASELINE_ARG = (ARGV.find((a) => a.startsWith('--baseline=')) || '').slice('--baseline='.length);
if (ARGV.includes('--write-baseline') && ARGV.some((a) => a.startsWith('--umbrella=')) && !BASELINE_ARG) {
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

const BASELINE_PATH = BASELINE_ARG ? path.resolve(BASELINE_ARG) : path.join(__dirname, 'check-doc-narration-baseline.json');
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

// BACKLOG.md's closed items and its open items' lengths (header, SCOPE). An index it cannot read is one this run checked
// nothing in: no pass.
const BACKLOG_PATH = path.join(DOCS, 'BACKLOG.md');
if (!fs.existsSync(BACKLOG_PATH)) { console.error(`[doc-narration] ERROR — no ${BACKLOG_PATH}: a run that cannot read the open-items index checked nothing there — no pass`); process.exit(2); }
// A task-list item at any depth, any bullet (`-` `*` `+` `1.` `1)`), inside a quote too; a fenced block is skipped.
const TASK_ITEM = /^\s*(?:>\s*)*(?:[-*+]|\d+[.)])\s+\[([ xX])\](?=\s|$)/;
// the ceiling --write-baseline may record for an open item's length: an index line, never a page
const BACKLOG_ITEM_HARD_MAX = 400;
const closedItems = [];
const openItemLengths = [];   // { lineNo, chars, text }
let openItems = 0;
let item;                      // the open item being read: its task line and every line Markdown makes part of it
const closeItem = () => { if (item) openItemLengths.push(item); item = undefined; };
// An item is FOUND on the prose line (inline code stripped, so a `- [x]` quoted in code is no item; a fenced block
// holds none) and MEASURED on its raw text. Its lines are the ones Markdown renders as part of it: a line indented
// deeper than its task line (after a blank line too), a fenced block opened inside it, a quoted item's quoted lines,
// and a LAZY continuation — an unindented line straight after its text that opens no block of its own. Inline code
// and fenced lines count: a pointer's path is part of the line a reader reads.
const QUOTE_PREFIX = /^(?:\s*>)+ ?/;
const unquoted = (s) => s.replace(QUOTE_PREFIX, '');
const indentOf = (s) => s.search(/\S/);
const FENCE = /^\s*```/;
const OPENS_A_BLOCK = /^\s*(?:[-*+]\s|\d+[.)]\s|#|```|\||<)/;   // a list item, a heading, a fence, a table, HTML
const backlogRaw = fs.readFileSync(BACKLOG_PATH, 'utf8').split('\n');
let fence;                     // while inside a fenced block: { inItem } — whether the block belongs to the open item
let afterBlank = false;
backlogRaw.forEach((raw, i) => {
  const lineNo = i + 1;
  const body = unquoted(raw);
  if (fence) {
    if (fence.inItem && item) item.text += ' ' + raw.trim();
    if (FENCE.test(body)) fence = undefined;
    return;
  }
  if (FENCE.test(body)) {
    fence = { inItem: !!item && indentOf(body) > item.indent };
    if (fence.inItem) item.text += ' ' + raw.trim(); else closeItem();
    afterBlank = false;
    return;
  }
  const m = raw.replace(/`[^`]*`/g, '').match(TASK_ITEM);
  if (m) {
    closeItem();
    if (m[1] === ' ') { openItems++; item = { lineNo, indent: indentOf(body), quoted: QUOTE_PREFIX.test(raw), text: raw.trim() }; }
    else closedItems.push(`  docs/BACKLOG.md:${lineNo}  [closed item]  …${raw.replace(/`[^`]*`/g, '').trim().slice(0, 110)}`);
    afterBlank = false;
    return;
  }
  if (!body.trim()) { afterBlank = true; return; }      // a blank line keeps the item open: the next line decides
  if (item) {
    const deeper = indentOf(body) > item.indent && (!item.quoted || QUOTE_PREFIX.test(raw));
    const lazy = !afterBlank && !OPENS_A_BLOCK.test(body);
    if (deeper || lazy) { item.text += ' ' + raw.trim(); afterBlank = false; return; }
  }
  closeItem();
  afterBlank = false;
});
closeItem();
for (const it of openItemLengths) it.chars = it.text.replace(/\s+/g, ' ').length;
const longestOpenItem = openItemLengths.reduce((a, b) => (b.chars > a ? b.chars : a), 0);

if (write) {
  if (longestOpenItem > BACKLOG_ITEM_HARD_MAX) {
    console.error(`[doc-narration] ERROR — the longest open item of docs/BACKLOG.md is ${longestOpenItem} characters, over ` +
      `${BACKLOG_ITEM_HARD_MAX}: shorten it (its detail goes to the plan that owns it) before recording a ceiling — nothing written`);
    process.exit(2);
  }
  fs.writeFileSync(BASELINE_PATH, JSON.stringify({ narration: counts, instructionBytes: bytes, backlogItemChars: longestOpenItem }, null, 2) + '\n');
  console.log(hits.join('\n'));
  console.log(`\nbaseline written: ${total} line(s) across ${Object.keys(counts).length} file(s); ceilings ` +
    INSTRUCTION_FILES.map((f) => `${f} ${bytes[f]} bytes`).join(', ') + `, an open BACKLOG item ${longestOpenItem} characters.`);
  process.exit(0);
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

// each open item against the recorded ceiling; a baseline with none is one this run cannot judge: no pass
const itemCeiling = baselineFile.backlogItemChars;
if (!Number.isInteger(itemCeiling)) {
  console.error(`[doc-narration] ERROR — no open-item ceiling (backlogItemChars) in ${BASELINE_PATH}: record one with --write-baseline — no pass`);
  process.exit(2);
}
const longItems = openItemLengths.filter((it) => it.chars > itemCeiling)
  .map((it) => `  docs/BACKLOG.md:${it.lineNo}  [${it.chars} > ${itemCeiling} characters]  …${it.text.slice(0, 90)}`);

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
if (longItems.length) {
  if (closedItems.length || risen.length || over.length) console.log('');
  console.log(`BACKLOG ITEM OVER THE INDEX CEILING — ${longItems.length} item(s):`);
  for (const line of longItems) console.log(rules.fired('BACKLOG_ITEM_TOO_LONG', line));
  console.log('\ndocs/BACKLOG.md is an INDEX (docs/README.md filing rule 5): an item says what is wrong or what is to do, its');
  console.log('reach or severity, and where its detail lives; the detail goes, verbatim, to the plan that owns it.');
}
if (closedItems.length || risen.length || over.length || longItems.length) process.exit(1);

console.log(`OK — ${scanned} docs in ${BUCKETS.join('/')}; ${total} narration line(s), baseline ${baseTotal}; ` +
  `BACKLOG.md ${openItems} open item(s), 0 closed; ` +
  INSTRUCTION_FILES.map((f) => `${f} ${bytes[f]} of ${ceilings[f]} bytes`).join(', ') + '.');
for (const rel of INSTRUCTION_FILES) if (bytes[rel] < ceilings[rel]) improved.push(`  ${rel}: ceiling ${ceilings[rel]} -> ${bytes[rel]} bytes`);
if (longestOpenItem < itemCeiling) improved.push(`  docs/BACKLOG.md: open-item ceiling ${itemCeiling} -> ${longestOpenItem} characters`);
if (improved.length) {
  console.log('IMPROVED — bank it with `node buildSystem/check-doc-narration.js --write-baseline`:');
  console.log(improved.join('\n'));
}
process.exit(0);

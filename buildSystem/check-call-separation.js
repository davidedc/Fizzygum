#!/usr/bin/env node
'use strict';
/*
 * check-call-separation.js — build gate for the public/private call-separation rules [S] and [U]
 * (docs/public-private-call-separation-plan.md; gate reference: docs/lint-and-static-checks.md §3/§4).
 * The MEASUREMENT lives in buildSystem/census-public-private-calls.js (one engine, two entry points:
 * that file's CLI reports, this gate enforces).
 *
 * [S] — a PRIVATE method (leading `_`/`__` or `*NoSettle`) must not @-self-call a public COMMAND:
 *       a callee that (transitively, over @-self calls) SETTLES, or is EFFECTFUL (mutates own
 *       state / repaints / schedules layout). Public QUERIES and the react verbs changed/
 *       fullChanged are expressly allowed — that command/query cut is the whole point (the literal
 *       "no public self-calls from private code" was measured 2026-07-12 to be ~85% benign query
 *       noise and REJECTED — plan §8). A site whose CALLER method carries
 *       `# public-call-sanctioned: <why>` is exempt (the census reports it as sanctioned).
 *       RATCHET: two inline baselines (SETTLING / EFFECTFUL), the check-stinks.js idiom — the
 *       build FAILS when a count EXCEEDS its baseline; when it drops, tighten the baseline to lock
 *       the gain (the gate prints a reminder). Baseline 0 = a HARD rule.
 *
 * [U] — a public method whose EVERY reference (src + test harness + macro tests, strings included)
 *       is a `@`-self call is provably NOT external API and must be `_`-tier. Counted split
 *       EFFECTFUL (the commands rule [S] cares about — rename first) / QUERY (cosmetic).
 *       Deliberate end-user API (Fizzygum is live-editable: a method can exist solely for a user
 *       to call from the in-world Object Inspector / scripting) goes in
 *       buildSystem/public-api-allowlist.txt (name + reason — the dead-method-allowlist idiom).
 *       NEEDS the sibling Fizzygum-tests repo for a sound reference set: SKIPS (never false-fails)
 *       when it is absent (e.g. a --homepage build), exactly like check-dead-methods.js.
 *
 * Relationship to the other gates: [A]/[G] (check-layering) ban the DIRECT low-level→settling
 * calls; [S] extends the ban to transitively-settling and effectful callees — closing the one-hop
 * blind spot that let StretchableEditableWdgt cores reach @add through a public builder, and
 * ColorPickerWdgt's constructor evade check-constructors-build the same way. [T] (in
 * check-layering.js) is the double-settle sibling. Dynamic dispatch stays invisible to all of
 * them — the runtime one-flush throw is the backstop.
 *
 * Exit codes: 0 clean · 1 violation (count exceeded a baseline) · 2 operational error.
 * Run from the Fizzygum/ repo root (build_it_please.sh does): node ./buildSystem/check-call-separation.js
 * Self-test: plant a `_foo: -> @somePublicCommand()` in a throwaway src class, confirm the count
 * bumps past the baseline and the build aborts; `# public-call-sanctioned: fixture` exempts it.
 */

const fs = require('fs');
const path = require('path');
const { runCensus } = require('./census-public-private-calls.js');

// ---- [S] baselines (RATCHET — tighten as the plan's tranches drain the sites; 0 = HARD) ----
// Seeded 2026-07-12 from the census at rule birth (plan §3 snapshot: 2 SETTLING — the
// StretchableEditableWdgt one-hop pair — and 81 EFFECTFUL across 43 classes).
const BASELINE_S_SETTLING = 0;     // HARD since T2 (2026-07-12): the StretchableEditableWdgt one-hop pair was converted to _createNewStretchablePanelNoSettle
const BASELINE_S_EFFECTFUL = 0;    // HARD since T3 (2026-07-12): 81 at rule birth -> 51 (T1 markLayoutAsFixed rename) -> 0 (T3: 27 internal verbs renamed to _-tier + 18 dual-use sites consciously marked public-call-sanctioned)

// ---- [U] baselines (RATCHET — fails only on a NEW self-only public method, like dead-methods) ----
const BASELINE_U_EFFECTFUL = 0;    // HARD since T5 (2026-07-12): 92 at rule birth -> 76 (T2/T3) -> 0 (T5: 53 renames + 23 allowlisted; owner triage in plan App-F)
const BASELINE_U_QUERY = 150;      // 152 at rule birth; T2 deleted the vestigial buildSubwidgets hooks; T5's renames took 1 more off
const ALLOWLIST = path.resolve(__dirname, 'public-api-allowlist.txt');

function readAllowlist() {
  const allow = new Set();
  if (fs.existsSync(ALLOWLIST)) {
    for (const l of fs.readFileSync(ALLOWLIST, 'utf8').split('\n')) {
      const t = (l.indexOf('#') >= 0 ? l.slice(0, l.indexOf('#')) : l).trim();
      if (t) allow.add(t);
    }
  }
  return allow;
}

let census;
try { census = runCensus(); }
catch (e) { console.error('[call-separation] operational error: ' + e.message); process.exit(2); }

const problems = [];
const notes = [];

// ---------- [S] ----------
const hard = census.R1.filter(r => (r.calleeClass === 'SETTLING' || r.calleeClass === 'EFFECTFUL') && !r.sanctioned);
const sSettling = hard.filter(r => r.calleeClass === 'SETTLING');
const sEffectful = hard.filter(r => r.calleeClass === 'EFFECTFUL');
const sanctionedCount = census.R1.filter(r => (r.calleeClass === 'SETTLING' || r.calleeClass === 'EFFECTFUL') && r.sanctioned).length;

function checkRatchet(label, rows, baseline, describe) {
  if (rows.length > baseline) {
    problems.push(`[S] ${label}: ${rows.length} unsanctioned site(s) EXCEEDS the baseline ${baseline} — a private method newly self-calls a public ${describe}. Fix it (rename the callee to _-tier, call its _<name>NoSettle core, or — for a conscious exception — mark the CALLER  # public-call-sanctioned: <why>); never raise the baseline to ship.`);
    for (const r of rows) problems.push(`    ${r.cls}.${r.caller} -> @${r.callee}  ${r.at}`);
  } else if (rows.length < baseline) {
    notes.push(`[S] ${label}: ${rows.length} < baseline ${baseline} — tighten BASELINE_S_${label} in check-call-separation.js to lock the gain.`);
  }
}
checkRatchet('SETTLING', sSettling, BASELINE_S_SETTLING, 'settling command (it opens a second flush)');
checkRatchet('EFFECTFUL', sEffectful, BASELINE_S_EFFECTFUL, 'effectful command');

// ---------- [U] ----------
let uMsg = 'SKIPPED (sibling Fizzygum-tests not present — needs its reference set)';
if (census.R4) {
  const allow = readAllowlist();
  const candidates = census.R4.filter(r => !allow.has(r.name));
  const uEff = candidates.filter(r => r.effectful);
  const uQry = candidates.filter(r => !r.effectful);
  const stale = [...allow].filter(n => !census.R4.some(r => r.name === n));
  if (stale.length) notes.push(`[U] ${stale.length} allowlist entr${stale.length === 1 ? 'y is' : 'ies are'} no longer self-only-public (delete from public-api-allowlist.txt): ${stale.join(', ')}`);
  if (uEff.length > BASELINE_U_EFFECTFUL) {
    problems.push(`[U] EFFECTFUL self-only public methods: ${uEff.length} EXCEEDS the baseline ${BASELINE_U_EFFECTFUL} — a NEW public command is referenced only by @-self calls, i.e. it is not external API. Name it _-tier from the start (or, if it is deliberate end-user API for the in-world inspector/scripting, add it to buildSystem/public-api-allowlist.txt with a reason).`);
    const newest = uEff.slice(0, 10).map(r => `${r.name} (${r.defs.slice(0, 3).join(', ')})`);
    problems.push(`    candidates include: ${newest.join('; ')}  — run  node ./buildSystem/census-public-private-calls.js --full  to identify the new one`);
  } else if (uEff.length < BASELINE_U_EFFECTFUL) {
    notes.push(`[U] EFFECTFUL: ${uEff.length} < baseline ${BASELINE_U_EFFECTFUL} — tighten BASELINE_U_EFFECTFUL to lock the gain.`);
  }
  if (uQry.length > BASELINE_U_QUERY) {
    problems.push(`[U] QUERY self-only public methods: ${uQry.length} EXCEEDS the baseline ${BASELINE_U_QUERY} — a NEW public query is referenced only by @-self calls. Name it _-tier from the start (or allowlist deliberate end-user API).`);
  } else if (uQry.length < BASELINE_U_QUERY) {
    notes.push(`[U] QUERY: ${uQry.length} < baseline ${BASELINE_U_QUERY} — tighten BASELINE_U_QUERY to lock the gain.`);
  }
  uMsg = `${uEff.length}/${BASELINE_U_EFFECTFUL} effectful + ${uQry.length}/${BASELINE_U_QUERY} query self-only public methods (${allow.size} allowlisted)`;
}

for (const n of notes) console.log('[call-separation] NOTE — ' + n);
if (problems.length) {
  console.error(`\n!!! call-separation gate FAILED:\n`);
  for (const p of problems) console.error('  ' + p);
  console.error('\nRules [S]/[U] — docs/public-private-call-separation-plan.md; measurement: node ./buildSystem/census-public-private-calls.js');
  process.exit(1);
}
console.log(`[call-separation] OK — [S] ${sSettling.length}/${BASELINE_S_SETTLING} settling + ${sEffectful.length}/${BASELINE_S_EFFECTFUL} effectful unsanctioned private->public-command sites (${sanctionedCount} sanctioned); [U] ${uMsg}.`);
process.exit(0);

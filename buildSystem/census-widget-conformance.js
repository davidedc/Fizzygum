#!/usr/bin/env node
// census-widget-conformance.js — the widget-practices CENSUS.
//
// Re-derives on demand the MECHANICAL facets of
// docs/measurements/widget-practices-survey-2026-08-14.md, so that survey stops being a one-off
// snapshot somebody has to redo by hand before every phase of
// docs/plans/widget-practices-convergence-plan.md. It is the re-runnable half of that survey; the
// judgement half stays in the prose.
//
// TWO MODES, and the split is the point (lint-and-static-checks.md §3b — sound negative => hard gate,
// count-shaped smell => ratcheted stink, heuristic => advisory census):
//   (default)  ADVISORY. Prints every facet, always exits 0. `--json` for a machine reader.
//   --gate     RATCHET. Checks ONLY the two facets objective enough to ratchet (facet 1 and facet 2:
//              a name is declared or it is not; a prologue is repeated or it is not) and exits 1 if
//              either rises above its baseline. This is what the build runs.
// Facets 3-6 are heuristics with known false positives and must NEVER gate — each says why below.
//
// ⚠⚠ THE BASELINES ARE FLOORS, NOT INVENTORIES. Both are non-zero on purpose, and every remaining
// occurrence is a STATED DECISION listed beside it. A green run means "nothing got worse" — it never
// means "nothing is left". Lowering a baseline after clearing occurrences is part of the work; raising
// one needs a one-line reason here, exactly like check-stinks.js.

const fs = require('fs');
const path = require('path');
const SRC = path.resolve(__dirname, '../src');

// ── the two ratcheted floors ────────────────────────────────────────────────────────────────────
const BASELINE_UNDECLARED_CLASSES = 9;   // W4c floor: all of it the `target`/`callback` pair, left
const BASELINE_UNDECLARED_FIELDS  = 11;  // undeclared pending the connector arc's P9 rename (plan D2)
// W5 floor: classes still repeating the _reLayout prologue instead of taking Widget's own-contents
// template. ButtonWdgt + ColorPickerWdgt (no _repaintAsOneUnit unit, and ButtonWdgt's pass reads the
// granted bounds); SimpleSpreadsheetWdgt, SpeechBubbleWdgt, StretchableCanvasWdgt,
// StretchablePanelWdgt, SwitchButtonWdgt (five genuinely different shapes — plan §2.5's table);
// InspectorWdgt (collapse guard before the bounds calc, and _applyBounds rather than the granted twin).
const BASELINE_PROLOGUE_COPIES = 8;

const args = process.argv.slice(2);
const GATE = args.includes('--gate');
const JSON_OUT = args.includes('--json');

function walk(dir, acc = []) {
  if (!fs.existsSync(dir)) return acc;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (e.name.endsWith('.coffee')) acc.push(p);
  }
  return acc;
}
// naive comment strip — the same trade every scanner in this directory makes
const strip = (s) => s.split('\n').map((l) => (l.indexOf('#') < 0 ? l : l.slice(0, l.indexOf('#')))).join('\n');

// ── parse every source once ─────────────────────────────────────────────────────────────────────
const classes = new Map();   // name -> { parent, text, file }
const mixins  = new Map();   // name -> text
for (const p of walk(SRC)) {
  const text = fs.readFileSync(p, 'utf8');
  const c = /^class\s+(\w+)(?:\s+extends\s+(\w+))?/m.exec(text);
  if (c) classes.set(c[1], { parent: c[2], text, file: path.relative(SRC, p) });
  const m = /^(\w+Mixin)\s*=/m.exec(text);
  if (m) mixins.set(m[1], text);
}
function chain(name) {
  const out = [];
  for (let c = name, guard = 0; c && guard < 40; c = classes.get(c)?.parent, guard++) {
    out.push(c);
    if (!classes.has(c)) break;
  }
  return out;
}
const isWidget = (name) => name === 'Widget' || chain(name).slice(1).includes('Widget');
// a class-level declaration is `  name: <not a function>`; a mixin's sits deeper
function declarationsOf(name) {
  if (classes.has(name)) return new Set([...classes.get(name).text.matchAll(/^ {2}([A-Za-z_]\w*)\s*:\s*(?!\(|->|=>)/gm)].map((m) => m[1]));
  if (mixins.has(name))  return new Set([...mixins.get(name).matchAll(/^\s{4,}([A-Za-z_]\w*)\s*:\s*(?!\(|->|=>)/gm)].map((m) => m[1]));
  return new Set();
}
const mixinsOf = (name) => [...(classes.get(name)?.text || '').matchAll(/@augmentWith\s+(\w+)/g)].map((m) => m[1]);

// ── facet 1 (RATCHETED) — instance fields written but never declared at class level ─────────────
// A prototype declaration is what makes a lazily-initialised field visible to duplication,
// serialization and the inspector (plan §3.3). Mixin-aware: a field a mixin donates IS declared, and
// re-declaring it in the class body would CLOBBER the donated value (plan §3.4).
function undeclaredFields() {
  const rows = [];
  for (const name of [...classes.keys()].sort()) {
    if (!isWidget(name)) continue;
    const ch = chain(name);
    const declared = new Set();
    for (const a of [...ch, ...new Set(ch.flatMap(mixinsOf))]) for (const d of declarationsOf(a)) declared.add(d);
    const body = strip(classes.get(name).text);
    const written = new Set([...body.matchAll(/@([a-z_]\w*)\s*=(?!=|>)/g)].map((m) => m[1]));
    const ctor = /^ {2}constructor:\s*\(([^)]*)\)/m.exec(body);
    if (ctor) for (const m of ctor[1].matchAll(/@([A-Za-z_]\w*)/g)) written.add(m[1]);
    const missing = [...written].filter((f) => !declared.has(f)).sort();
    if (missing.length) rows.push({ cls: name, file: classes.get(name).file, fields: missing });
  }
  return rows;
}

// ── facet 2 (RATCHETED) — _reLayout prologue copies ─────────────────────────────────────────────
// The own-contents shape belongs in Widget._reLayoutWithOwnContents (plan §2.5 / W5). A class still
// spelling the prologue out is either an unconverted copy or a deliberate exception — the baseline
// above names today's eight.
function prologueCopies() {
  const rows = [];
  for (const name of [...classes.keys()].sort()) {
    if (name === 'Widget' || !isWidget(name)) continue;
    const body = strip(classes.get(name).text);
    if (/@__calculateNewBoundsWhenDoingLayout/.test(body)) rows.push({ cls: name, file: classes.get(name).file });
  }
  return rows;
}

// ── facet 3 (ADVISORY) — widgets with no colloquialName ─────────────────────────────────────────
// ⚠ NEVER gate: plenty of internal widgets have no business naming themselves, and a colloquial name
// is DRAWN (window titles, hierarchy menus), so adding one moves pixels. Plan §2.7 / D4.
const missingColloquialName = () =>
  [...classes.keys()].sort().filter((n) => isWidget(n) && !/^ {2}colloquialName\s*:/m.test(classes.get(n).text));

// ── facet 4 (ADVISORY) — constructor positional-slot counts ─────────────────────────────────────
// ⚠ NEVER gate on the number alone: value/geometry tuples and published user-facing spellings stay
// positional however long they are (architecture/constructor-and-parameter-conventions.md). The
// decisive test is the HOLE test, which check-argument-holes.js owns.
function constructorSlots() {
  const rows = [];
  for (const name of [...classes.keys()].sort()) {
    if (!isWidget(name)) continue;
    const m = /^ {2}constructor:\s*\(([^)]*)\)/m.exec(strip(classes.get(name).text));
    if (!m || !m[1].trim()) continue;
    const slots = m[1].split(',').filter((s) => s.trim()).length;
    const hasOpts = /\bopts\s*=|\bopts\b/.test(m[1]);
    if (slots > 4 && !hasOpts) rows.push({ cls: name, slots, file: classes.get(name).file });
  }
  return rows;
}

// ── facet 5 (ADVISORY) — pin-setter argument shapes ─────────────────────────────────────────────
// ⚠ NEVER gate: the tree has legitimate variants (ScrollPanelWdgt's conditional forward,
// NumberPromptWdgt's pure sink), and the whole area is mid-flight between this plan's W6 and
// plans/connector-ubiquity-and-reflection-plan.md. Reported so W6 can re-derive its table, not judged.
function pinSetterShapes() {
  const rows = [];
  for (const name of [...classes.keys()].sort()) {
    if (!isWidget(name)) continue;
    for (const m of strip(classes.get(name).text).matchAll(/^ {2}(set[A-Z]\w*)\s*:\s*\(([^)]*)\)/gm)) {
      const params = m[2].split(',').map((s) => s.trim()).filter(Boolean);
      rows.push({ cls: name, setter: m[1], arity: params.length, params: params.join(', ') });
    }
  }
  return rows;
}

// ── facet 6 (ADVISORY) — classes with no header comment ─────────────────────────────────────────
// ⚠ NEVER gate: "has a comment above the class line" is not "is documented". A prompt for a human.
const missingHeaderComment = () =>
  [...classes.keys()].sort().filter((n) => {
    if (!isWidget(n)) return false;
    const lines = classes.get(n).text.split('\n');
    const at = lines.findIndex((l) => /^class\s+\w/.test(l));
    for (let i = at - 1; i >= 0; i--) {
      if (!lines[i].trim()) continue;
      return !lines[i].trim().startsWith('#');
    }
    return true;
  });

// ── report ──────────────────────────────────────────────────────────────────────────────────────
const undeclared = undeclaredFields();
const prologues = prologueCopies();
const undeclaredFieldCount = undeclared.reduce((n, r) => n + r.fields.length, 0);

if (GATE) {
  const fails = [];
  if (undeclared.length > BASELINE_UNDECLARED_CLASSES || undeclaredFieldCount > BASELINE_UNDECLARED_FIELDS) {
    fails.push(`undeclared instance fields: ${undeclared.length} class(es) / ${undeclaredFieldCount} field(s) ` +
               `-- baseline ${BASELINE_UNDECLARED_CLASSES}/${BASELINE_UNDECLARED_FIELDS}`);
    for (const r of undeclared) fails.push(`    ${r.cls} (${r.file}): ${r.fields.join(', ')}`);
  }
  if (prologues.length > BASELINE_PROLOGUE_COPIES) {
    fails.push(`_reLayout prologue copies: ${prologues.length} -- baseline ${BASELINE_PROLOGUE_COPIES}`);
    for (const r of prologues) fails.push(`    ${r.cls} (${r.file})`);
  }
  if (fails.length) {
    console.error('\n[widget-conformance] FAIL -- a ratcheted count rose above its baseline:');
    for (const f of fails) console.error('  ' + f);
    console.error('\nFix the occurrence (preferred) -- declare the field at class level, or take');
    console.error('Widget._reLayoutWithOwnContents. If the new occurrence is genuinely intentional, raise the');
    console.error('baseline in buildSystem/census-widget-conformance.js WITH a one-line reason, as check-stinks.js does.');
    process.exit(1);
  }
  console.log(`[widget-conformance] OK -- undeclared fields ${undeclared.length}/${undeclaredFieldCount} ` +
              `(baseline ${BASELINE_UNDECLARED_CLASSES}/${BASELINE_UNDECLARED_FIELDS}), ` +
              `prologue copies ${prologues.length} (baseline ${BASELINE_PROLOGUE_COPIES}). Baselines are FLOORS, not inventories.`);
  process.exit(0);
}

const slots = constructorSlots();
const setters = pinSetterShapes();
const noName = missingColloquialName();
const noHeader = missingHeaderComment();
const widgetCount = [...classes.keys()].filter(isWidget).length;

if (JSON_OUT) {
  console.log(JSON.stringify({
    widgetClasses: widgetCount,
    ratcheted: {
      undeclaredFields: { classes: undeclared.length, fields: undeclaredFieldCount,
                          baseline: { classes: BASELINE_UNDECLARED_CLASSES, fields: BASELINE_UNDECLARED_FIELDS }, rows: undeclared },
      prologueCopies: { count: prologues.length, baseline: BASELINE_PROLOGUE_COPIES, rows: prologues },
    },
    advisory: {
      missingColloquialName: noName,
      constructorsOverFourPositionalSlots: slots,
      pinSetters: setters,
      missingHeaderComment: noHeader,
    },
  }, null, 2));
  process.exit(0);
}

console.log(`\n[widget-conformance] ${widgetCount} widget classes under src/.\n`);
console.log(`RATCHETED (these two also run as --gate on the build; both baselines are FLOORS)`);
console.log(`  1. undeclared instance fields : ${undeclared.length} class(es) / ${undeclaredFieldCount} field(s)  [baseline ${BASELINE_UNDECLARED_CLASSES}/${BASELINE_UNDECLARED_FIELDS}]`);
for (const r of undeclared) console.log(`       ${r.cls.padEnd(38)} ${r.fields.join(', ')}`);
console.log(`  2. _reLayout prologue copies  : ${prologues.length}  [baseline ${BASELINE_PROLOGUE_COPIES}]`);
for (const r of prologues) console.log(`       ${r.cls.padEnd(38)} ${r.file}`);
console.log(`\nADVISORY (heuristics — each has real exceptions; none of these may ever gate)`);
console.log(`  3. no colloquialName          : ${noName.length} of ${widgetCount}   (DRAWN when added — plan D4)`);
console.log(`  4. >4 positional ctor slots, no opts bag : ${slots.length}`);
for (const r of slots) console.log(`       ${r.cls.padEnd(38)} ${r.slots} slots`);
console.log(`  5. pin setters                : ${setters.length} setter(s) across ${new Set(setters.map((s) => s.cls)).size} class(es)`);
const byArity = setters.reduce((a, s) => (a[s.arity] = (a[s.arity] || 0) + 1, a), {});
console.log(`       arity histogram: ${Object.entries(byArity).sort().map(([k, v]) => `${k}->${v}`).join('  ')}`);
console.log(`  6. no header comment          : ${noHeader.length} of ${widgetCount}`);
console.log(`\n(--json for the full machine-readable dump; --gate for the ratchet the build runs.)`);
process.exit(0);

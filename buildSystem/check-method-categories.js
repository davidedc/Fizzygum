#!/usr/bin/env node
'use strict';
// check-method-categories.js — the METHOD-CATEGORY marker, `  #: <category>` at the member column, held to its form,
// and the classes that name no category yet held to a BUDGET that falls (docs/architecture/lint-and-static-checks.md
// §3b).
//   A marker is a COMMENT the meta-system reads (src/meta/Class.coffee): it gives its category to every member after it,
// up to the next marker, and a class's record keeps what it gives (its categoryOf and categories()). It excludes nothing
// and changes no compiled byte, so it is no successor of the retired exclusion markers (check-region-markers.js,
// check-whole-file-markers.js), whose lesson stands.
//
// THE PRODUCT'S OWN READING, so the gate and the page cannot disagree. The tree's own Class.coffee, loaded by
// lib/meta-compiler.js as check-coffee-syntax.js loads it, parses every class file (`_parsedSource`): its record says
// each member's SOURCE and CATEGORY and the class's category names. Each line of the file is read as the parse reads a
// stash (`_commentAndMarkersOf`: whether the line is a marker, and of which category — the name rule is
// Class.isACategoryName), and as the meta-system's comment rule reads text (Class.isAComment). Each member is placed on
// its file's lines by the rule lib/call-sites.js shares (lib/meta-compiler.js placesOfMember; a member written twice is
// placed at its LAST writing, the one the parse's store keeps); a line no member's source holds is DROPPED — the lines
// above the `class` line (the class's comment), each member's stash, and whatever follows the last member. The `#:`
// lines are spotted by lib/coffee-mask.js (the lexer's reading: a `#:` inside a string or a heredoc is no comment, so
// no marker-shaped line); whether a dropped line is comment or code is the meta-system's own rule, Class.isAComment
// (STASH_HOLDS_CODE). A member is a
// METHOD when its source opens with a function literal, read by the product's own Widget.functionLiteralReading
// (compiled from Widget's record, as lib/coffee-method-header-selftest.js compiles it) — never by the shared header
// matcher. A field or a class-side member is never counted as a method here.
//   And the gate reads each member's category back off the lines (the last marker above it) and holds it to the
// parse's: a disagreement means this reading and the meta-system's have drifted apart, and nothing is judged.
//
// RULES:
//   MARKER_MISPLACED (B, zero)             a comment line opening `#:` where no marker is read: inside a member's code
//                                          (any indent but the member column's two spaces), above the `class` line
//                                          (the class's comment), or in a compiled file that holds no class
//   CATEGORY_NAME_MALFORMED (B, zero)      a `#:` comment at the member column that the parse does not read as a
//                                          marker: its name is no category's (Class.isACategoryName — lower-case
//                                          words, one space between two, none of them opening with `extends`), or
//                                          no single space follows the `#:`
//   STASH_HOLDS_CODE (A, zero)             a dropped line that is no comment (Class.isAComment): code the meta-system
//                                          never compiles. A comment or a marker typed at the member column INSIDE a
//                                          body ends the member above it there, and the rest of its body lands here
//   EMPTY_CATEGORY (B, zero)               a marker with no instance method under it before the next marker or the
//                                          class's end (each marker judged: a category may open more than once)
//   MARKED_CLASS_UNMARKED_METHOD (B, zero) in a class that names a category, an instance method above its first marker
//   UNMARKED_CLASSES_ABOVE_BUDGET (C)      the classes holding an instance method and naming no category are more than
//                                          UNMARKED_CLASSES_BUDGET's number for their repo (Fizzygum's src, the tests
//                                          repo's harness — a class counts once, however many methods it holds)
// A marker's blank lines above and below are the house's layout, not a rule here (no reader depends on them). A `###`
// block comment between members reads as code too: Class.isAComment reads its inner lines as no comment, as an editor's
// split of a member's text does (Class.splitLeadingComment). A failing run prints each fired rule's advice
// (lib/gate-advice.js).
//
// Exit 0 clean, 1 a rule fired, 2 nothing could be measured — the meta-compiler does not load, its parse keeps no
// categories, a reading this gate asks of it is gone (`_parsedSource`, `_commentAndMarkersOf`, Class.isAComment,
// Widget's functionLiteralReading), a class it cannot parse, a member whose source stands nowhere in its file, a text
// the lexer refuses, or a member's category read off the lines that is not the parse's. That every rule bites is proven
// on every build by check-method-categories-selftest.js.
//
// Run from Fizzygum/ (the build's gate table does): node ./buildSystem/check-method-categories.js [--src=DIR]
// [--tests-repo=DIR] — the rails read another src tree or tests repo (a copy carrying a plant).

const fs = require('fs');
const { rejectUnknownArgs, rejectPositionalArgs } = require('./lib/cli-args');
const { compiledFiles, sourceRoots, sourceName, SOURCE_RAILS } = require('./lib/source-files');
const { loadMetaCompiler, placesOfMember } = require('./lib/meta-compiler');
const { coffeeMask, isCommentOnly } = require('./lib/coffee-mask');
const { IS_CLASS } = require('./build');
const rules = require('./lib/gate-rules').forGate(__filename);
const { adviceLines, advisedAmong } = require('./lib/gate-advice');

const TAG = '[method-categories]';
const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, [...SOURCE_RAILS], 'check-method-categories');
rejectPositionalArgs(ARGV, 'method-categories', 'a src tree is named with --src=DIR');
const ROOTS = sourceRoots(ARGV, 'method-categories');

// the classes holding an instance method and naming no category, one number per repo — recorded 2026-11-28 at the
// tree's own counts, the day this gate first read the tree, when no class held a marker; lowered whenever fewer remain
// (a class marked whole), and raised only in the change that needs it, its dated reason beside the number
const UNMARKED_CLASSES_BUDGET = {
  // lowered 520 -> 433 on 2026-11-28: the inspector browser's U6 marked the 87 classes of decision D1 (the meta-tools
  // part, the named classes, the desktop's and the Examples folder's apps, what their windows hold, every superclass)
  fizzygum: 433,
  tests: 13,
};
const HALVES = [
  { repo: 'fizzygum', label: 'Fizzygum', owns: (f) => !f.harness },
  { repo: 'tests', label: 'Fizzygum-tests', owns: (f) => f.harness },
];

const short = (s, n = 60) => { s = String(s).trim(); return s.length > n ? s.slice(0, n - 3) + '...' : s; };
const stop = (lines) => {
  for (const l of [].concat(lines)) console.error(`${TAG} ERROR — ${l}`);
  process.exit(2);
};

// ---- measure everything first: a run that cannot measure fires no rule
let CoffeeScript, Class;
try {
  ({ CoffeeScript, Class } = loadMetaCompiler({ srcDir: ROOTS.src, compileFGCode: () => '(function() {});' }));
} catch (e) {
  stop(e.message);
}
const proto = Class.prototype;
for (const [what, ok] of [
  ['Class.prototype._parsedSource', typeof proto._parsedSource === 'function'],
  ['Class.prototype._commentAndMarkersOf', typeof proto._commentAndMarkersOf === 'function'],
  ['Class.prototype.classRegex', proto.classRegex instanceof RegExp],
  ['Class.isAComment', typeof Class.isAComment === 'function'],
]) {
  if (!ok) stop(`${what} is gone: the meta-system no longer offers the reading this gate asks of it — re-read src/meta/Class.coffee`);
}
const parse = (text) => proto._parsedSource.call(Object.create(proto), text);
// the categories the parse reads off one line, as it reads a stash: [] for a line that is no marker
const markersOf = (line) => {
  const read = proto._commentAndMarkersOf.call(proto, line);
  return Array.isArray(read) && Array.isArray(read[1]) ? read[1] : undefined;
};
const SIDES = [
  { isStatic: false, sources: 'nonStaticPropertiesSources', categories: 'nonStaticPropertiesCategories' },
  { isStatic: true, sources: 'staticPropertiesSources', categories: 'staticPropertiesCategories' },
];

const problems = [];
const files = [];
let widgetRecord;
for (const p of compiledFiles(ROOTS)) {
  const text = fs.readFileSync(p, 'utf8');
  const name = sourceName(p, ROOTS);
  const f = { name, harness: name.startsWith('harness/'), lines: text.split('\n'), isClass: IS_CLASS.test(text) };
  files.push(f);
  try { f.mask = coffeeMask(text, name); } catch (e) { problems.push(e.message); continue; }
  if (!f.isClass) continue;
  // the parse prints its own debug lines only under a flag the shim keeps off; it throws on a text it cannot read
  try { f.rec = parse(text); } catch (e) { problems.push(`the meta-compiler cannot parse ${name}: ${e.message}`); continue; }
  const rec = f.rec;
  if (!SIDES.every((s) => rec[s.sources] && rec[s.categories] && typeof rec[s.categories] === 'object') || !Array.isArray(rec.categoryNames)) {
    stop(`the meta-compiler's parse of ${name} keeps no categories (no ${SIDES.map((s) => s.categories).join(' / ')} store, or no categoryNames list): src/meta/Class.coffee no longer reads the markers this gate holds`);
  }
  if (rec.name === 'Widget') widgetRecord = rec;
  f.classLine = f.lines.findIndex((l) => proto.classRegex.test(l));
  if (f.classLine < 0) { problems.push(`${name} holds no line the meta-system reads as its class line`); continue; }
  // each member on its lines; owner[i] is the member whose source holds line i
  f.members = [];
  f.owner = new Array(f.lines.length).fill(undefined);
  for (const side of SIDES) {
    for (const [member, source] of Object.entries(rec[side.sources])) {
      const at = placesOfMember(f.lines, member, side.isStatic, source).filter((h) => h > f.classLine);
      if (!at.length) { problems.push(`${name}: the parse's source of ${rec.name}.${side.isStatic ? '@' : ''}${member} stands nowhere in the file`); continue; }
      const m = { name: member, isStatic: side.isStatic, source, header: at[at.length - 1] };
      m.last = m.header + source.split('\n').length - 1;
      for (let i = m.header; i <= m.last; i++) {
        if (f.owner[i]) problems.push(`${name}:${i + 1} is placed in two members' sources (${f.owner[i].name}, ${member})`);
        f.owner[i] = m;
      }
      f.members.push(m);
    }
  }
  f.members.sort((a, b) => a.header - b.header);
  // the lines the parse reads as markers: dropped lines after the class line, read as it reads a stash
  f.markers = [];
  for (let i = f.classLine + 1; i < f.lines.length; i++) {
    if (f.owner[i]) continue;
    const read = markersOf(f.lines[i]);
    if (!read) stop('Class.prototype._commentAndMarkersOf no longer answers [comment, markers]: re-read src/meta/Class.coffee');
    if (read.length) f.markers.push({ line: i, category: read[read.length - 1] });
  }
  // each member's category read off the lines, held to the parse's
  for (const m of f.members) {
    const above = f.markers.filter((k) => k.line < m.header);
    const byLines = above.length ? above[above.length - 1].category : '';
    const byParse = rec[m.isStatic ? 'staticPropertiesCategories' : 'nonStaticPropertiesCategories'][m.name] || '';
    if (byLines !== byParse) {
      problems.push(`${name}:${m.header + 1}: ${rec.name}.${m.isStatic ? '@' : ''}${m.name} stands under the marker ` +
        `${JSON.stringify(byLines)} by its lines and in the category ${JSON.stringify(byParse)} by the parse: this gate's reading and the meta-system's disagree`);
    }
  }
}
if (!problems.length) {
  const source = widgetRecord && widgetRecord.staticPropertiesSources.functionLiteralReading;
  if (typeof source !== 'string') stop("Widget records no class-side functionLiteralReading: the product's reading of which members are methods moved");
  let reading;
  try {
    reading = new Function('CoffeeScript', CoffeeScript.compile('reading = ' + source, { bare: true }) + '\nreturn reading;')(CoffeeScript);
  } catch (e) { stop(`Widget.functionLiteralReading does not compile here: ${e.message}`); }
  for (const f of files) for (const m of f.members || []) m.isMethod = !m.isStatic && reading(m.source) !== undefined;
}
if (problems.length) stop(problems);

// ---- judge
const failures = [];
let classes = 0, methods = 0, markers = 0;
const unmarked = new Map(HALVES.map((h) => [h.repo, 0]));
for (const f of files) {
  const where = (i) => `${f.name}:${i + 1}`;
  // the comment lines opening `#:`, wherever they stand
  const shaped = [];
  f.mask.forEach((r, i) => { if (isCommentOnly(r) && r.comment.startsWith('#:')) shaped.push(i); });
  if (!f.isClass) {
    for (const i of shaped) failures.push(rules.fired('MARKER_MISPLACED', `  MARKER_MISPLACED  ${where(i)}  "${short(f.lines[i])}" — in a file that holds no class: nothing reads it`));
    continue;
  }
  classes++;
  markers += f.markers.length;
  const cls = f.rec.name;
  const markerLines = new Set(f.markers.map((k) => k.line));
  for (const i of shaped) {
    const line = f.lines[i];
    const indent = line.slice(0, line.indexOf('#'));
    if (i < f.classLine) {
      failures.push(rules.fired('MARKER_MISPLACED', `  MARKER_MISPLACED  ${where(i)}  "${short(line)}" — above the class line: the meta-system reads it as ${cls}'s comment`));
    } else if (indent !== '  ') {
      const inside = f.owner[i] ? `inside ${cls}.${f.owner[i].isStatic ? '@' : ''}${f.owner[i].name}'s code, a comment of it` : 'comment text';
      failures.push(rules.fired('MARKER_MISPLACED', `  MARKER_MISPLACED  ${where(i)}  "${short(line)}" — at ${indent.length} column(s), not the member column's two spaces: ${inside}, which gives no member a category`));
    } else if (!markerLines.has(i)) {
      failures.push(rules.fired('CATEGORY_NAME_MALFORMED', `  CATEGORY_NAME_MALFORMED  ${where(i)}  "${short(line)}" — no marker: a marker is \`  #: \` and a category's name, lower-case words with one space between two, none of them opening with extends (Class.isACategoryName); the meta-system reads this line as comment text`));
    }
  }
  // the dropped lines that are no comment, one finding per run of them (blank lines inside a run keep it going)
  for (let i = 0; i < f.lines.length; i++) {
    if (f.owner[i] || i === f.classLine || Class.isAComment(f.lines[i])) continue;
    const first = i;
    let code = 0;
    for (; i < f.lines.length && !f.owner[i] && i !== f.classLine; i++) {
      if (!Class.isAComment(f.lines[i])) code++;
      else if (f.lines[i].trim() !== '') break;
    }
    const next = f.members.find((m) => m.header > first);
    const place = first < f.classLine ? 'above the class line'
      : next ? `among the lines above ${cls}.${next.isStatic ? '@' : ''}${next.name}` : `after ${cls}'s last member`;
    failures.push(rules.fired('STASH_HOLDS_CODE', `  STASH_HOLDS_CODE  ${where(first)}  ${code} line(s) of code ${place}, in no member's source: the meta-system never compiles them — "${short(f.lines[first])}"`));
  }
  // each marker has an instance method under it before the next marker or the class's end
  const instanceMethods = f.members.filter((m) => m.isMethod);
  f.markers.forEach((k, n) => {
    const until = n + 1 < f.markers.length ? f.markers[n + 1].line : f.lines.length;
    if (instanceMethods.some((m) => m.header > k.line && m.header < until)) return;
    const end = n + 1 < f.markers.length ? `the next marker (line ${until + 1})` : `${cls}'s end`;
    failures.push(rules.fired('EMPTY_CATEGORY', `  EMPTY_CATEGORY  ${where(k.line)}  "${k.category}" has no instance method under it before ${end}`));
  });
  // a class that names a category gives every instance method one
  if (f.rec.categoryNames.length) {
    for (const m of instanceMethods) {
      if (f.rec.nonStaticPropertiesCategories[m.name]) continue;
      failures.push(rules.fired('MARKED_CLASS_UNMARKED_METHOD', `  MARKED_CLASS_UNMARKED_METHOD  ${where(m.header)}  ${cls}.${m.name} stands above ${cls}'s first marker (line ${f.markers[0].line + 1}): in a class with categories, every method stands in one`));
    }
  }
  methods += instanceMethods.length;
  if (instanceMethods.length && !f.rec.categoryNames.length) {
    const half = HALVES.find((h) => h.owns(f));
    unmarked.set(half.repo, unmarked.get(half.repo) + 1);
  }
}

// ---- the budget, one number per repo
const notes = [];
const counts = [];
for (const h of HALVES) {
  const n = unmarked.get(h.repo), budget = UNMARKED_CLASSES_BUDGET[h.repo];
  counts.push(`${h.label} ${n} (budget ${budget})`);
  if (n > budget) {
    failures.push(rules.fired('UNMARKED_CLASSES_ABOVE_BUDGET', `  UNMARKED_CLASSES_ABOVE_BUDGET  ${h.label}: ${n} classes hold an instance method and name no category (budget ${budget})`));
  } else if (n < budget) {
    notes.push(`  NOTE ${h.label} holds ${n} classes with an instance method and no category: lower UNMARKED_CLASSES_BUDGET.${h.repo} to ${n} here, to lock the gain in`);
  }
}

console.log(`${TAG} ${files.length} compiled files (${classes} classes), ${methods} instance methods, ${markers} marker(s); ` +
  `the classes holding an instance method and naming no category: ${counts.join(', ')} -- ${notes.length ? 'UNDER' : 'OK'}`);
for (const n of notes) console.log(n);
if (failures.length) {
  console.error(`\n${TAG} FAIL — ${failures.length} problem(s):`);
  for (const f of failures) console.error(f);
  const advised = advisedAmong(rules.gate, rules.firedIds);
  if (advised.length) { console.error(''); for (const l of adviceLines(rules.gate, advised)) console.error(l); }
  process.exit(1);
}
console.log(`${TAG} OK -- every marker read where it stands, every class with categories marked whole, the unmarked classes at or under their budgets.`);
process.exit(0);

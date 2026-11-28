'use strict';
// check-method-categories-selftest.js — check-method-categories.js proved able to BITE, by running the REAL gate on a
// planted copy of src/ and of the tests repo's harness (lib/planted-src.js). The control carries every form the gate
// passes: a class comment above the class line, a field and a class-side method above the first marker, a category
// opened twice, a field and a class-side method under a marker beside a method, a member comment between a marker and
// its member, `#:` text inside a string and a heredoc (no comment, so no marker), a method spelled with no space after
// the colon (which the shared header matcher, lib/coffee-method-header.js, reads too) and one whose header a backslash
// continues (which it reads as no header, and its guard refuses as a build error in the gates that use it) — each a
// method by the product's reading, which this gate counts by — a class holding fields and class-side methods only (no
// instance method, so outside the budget), and a marked harness class; the control passes at its budget or under it
// (`-- UNDER` and its NOTE), as the tree stands. Then every form rule, each in a file of its own and seen on each of
// its lines (a marker above the class line, inside a body at four columns and at none, in the harness, in a compiled
// file that holds no class; a name in capitals, with no space after `#:`, with two spaces inside it, holding the word
// `extends`, with a word opening with it; two markers in a row, a marker over a field and a class-side method only, a
// marker after the last member; a method above a marked class's first marker; code above the class line, before the
// first member, and after a comment or a marker that cut a body), and no other rule on any planted file; the budget,
// in each repo, with as many unmarked classes as take each half one over its number; and three runs read INVALID
// (exit 2), each beside a planted violation that must not be judged: a parse that keeps no categories, a parse that
// gives no member the category its marker names (the gate's reading of the lines and the parse's disagree), and
// Widget recording no functionLiteralReading. Last, a tree one UNDER its budget passes (exit 0, `-- UNDER`, the NOTE
// naming the lower number, no rule): one unmarked class taken out of the copy, a real file, since no plant can lower a
// count. Each fired rule prints its advice (lib/gate-advice.js), each row and its class's shared text once; the
// control and the run under its budget none. Run by buildSystem/run-selftests.js on every build.

const fs = require('fs');
const path = require('path');
const { proveGate, runGate } = require('./lib/planted-src');
const { srcFiles } = require('./lib/source-files');

const GATE = path.join(__dirname, 'check-method-categories.js');
// the gate's summary line on a passing tree: at the budget, or under it (a class marked, its budget not yet lowered) —
// UNDER, then a NOTE; held of the control as the tree stands, and of the run one under its budget (below)
const PASSING_SUMMARY = /^\[method-categories\] \d+ compiled files .* -- (?:OK|UNDER\n {2}NOTE .*)$/m;

const text = (lines) => lines.join('\n') + '\n';

const MARKED = text([
  '# BiteProofMarked: every form the gate passes',
  'class BiteProofMarked',
  '',
  '  # a field and a class-side method above the first marker: neither is an instance method',
  '  size: 0',
  '  @made: -> new BiteProofMarked',
  '',
  '  #: accessing',
  '',
  '  # my size',
  '  sizeOf: ->',
  '    @size',
  '  #: drawing',
  '  paint: (ctx) ->',
  '    ctx',
  '  # a field under a marker, after a method of it',
  '  colour: "red"',
  '',
  '  #: accessing',
  '  resize: (n) ->',
  '    @size = n',
  '',
  '  #: testing',
  '  # a member comment between the marker and the member',
  '  isEmpty: ->',
  '    @size is 0',
  '  label: ->',
  '    "#: no marker, a string"',
  '  doc: ->',
  '    """',
  '    #: no marker, a heredoc line',
  '    """',
  '',
  '  #: lifecycle',
  '  @biteProofStaticUnder: -> 1',
  '  destroy: ->',
  '    @size = 0',
  '',
  '  #: printing',
  '  printOn:(stream) ->',
  '    stream',
  '',
  '  #: copying',
  '  copyInto: \\',
  '      (other) ->',
  '    other',
]);
const FIELDS_ONLY = text(['class BiteProofFieldsOnly', '', '  size: 0', '  @make: -> new BiteProofFieldsOnly']);
const HARNESS_MARKED = text(['class BiteProofHarnessMarked', '', '  #: accessing', '  value: -> 1']);

const MISPLACED = text([
  '#: accessing',                     // 1: above the class line
  'class BiteProofMisplaced',
  '',
  '  #: accessing',
  '  first: ->',
  '    1',
  '    #: drawing',                   // 7: inside first's body, at four columns
  '    2',
  '#: testing',                       // 9: inside first's body, at none
  '  second: ->',
  '    3',
]);
const HARNESS_MISPLACED = text(['class BiteProofHarnessMisplaced', '', '  #: accessing', '  first: ->', '    #: drawing', '    1']);
const NOT_A_CLASS = text(['# a compiled file that holds no class', '#: accessing', 'window.biteProofBoot = 1']);
const MALFORMED = text([
  'class BiteProofMalformed',
  '',
  '  #: accessing',
  '  a: -> 1',
  '  #: Accessing',                   // 5
  '  b: -> 2',
  '  #:accessing',                    // 7
  '  c: -> 3',
  '  #: drag  and drop',              // 9
  '  d: -> 4',
  '  #: extends things',              // 11
  '  e: -> 5',
  '  #: extendsfoo',                  // 13: the boot scan reads an edge to `foo` from it
  '  f: -> 6',
]);
const EMPTY = text([
  'class BiteProofEmpty',
  '',
  '  #: accessing',                   // 3: the next marker follows at once
  '  #: drawing',
  '  paint: -> 1',
  '',
  '  #: testing',                     // 7: a field and a class-side method only
  '  flag: true',
  '  @biteProofMake: -> new BiteProofEmpty',
  '',
  '  #: printing',
  '  show: -> 2',
  '  #: lifecycle',                   // 13: after the last member
]);
const UNMARKED_METHOD = text(['class BiteProofUnmarked', '', '  above: -> 0', '', '  #: accessing', '  below: -> 1']);
const STASH = text([
  'biteProofTop = 1',                 // 1: above the class line
  'class BiteProofStash',
  '  biteProofHidden = 2',            // 3: before the first member
  '',
  '  #: accessing',
  '  first: ->',
  '    1',
  '  # a comment at the member column inside a body ends the body here',
  '    2',                            // 9: the rest of first's body
  '  second: -> 3',
  '  #: drawing',
  '  paint: ->',
  '    x = 1',
  '  #: printing',
  '    x + 1',                        // 15: the rest of paint's body, two lines of code
  '',
  '    x + 2',
  '  show: -> 4',
]);
// a line of any rule but `rule` naming the planted file `file`
const otherRuleOn = (rule, file) => new RegExp(`^  (?!${rule}  )[A-Z_]+  (?:harness/|boot/)?${file}\\.coffee:`, 'm');

// The first src class of the copy at `dir` that the budget counts, by a plain reading of its text: a class line, an
// instance method on a one-line header, no marker. Never meta/Class.coffee or Widget.coffee, which the gate reads its
// readings from. The run that removes it holds the count to one less, so a pick the budget does not count fails it.
const anUnmarkedClassIn = (dir) => srcFiles(dir).find((p) => {
  if (p === path.join(dir, 'meta', 'Class.coffee') || path.basename(p) === 'Widget.coffee') return false;
  const text = fs.readFileSync(p, 'utf8');
  return /^class [A-Za-z_$]/m.test(text) && !/^ {2}#:/m.test(text) && /^ {2}[a-zA-Z_$][\w$]*: *(?:\([^)\n]*\))? *[-=]>/m.test(text);
});

proveGate({
  name: 'check-method-categories',
  gate: GATE,
  testsRepo: true,
  pass: /^\[method-categories\] OK/m,
  control: {
    plants: { 'BiteProofMarked.coffee': MARKED, 'BiteProofFieldsOnly.coffee': FIELDS_ONLY,
      'harness/BiteProofHarnessMarked.coffee': HARNESS_MARKED },
    absent: [/BiteProof/],
    lines: [PASSING_SUMMARY],
  },
  runs: (control) => {
    // the budget run plants, in each repo, as many unmarked classes as take its half one over its number
    const m = /Fizzygum (\d+) \(budget (\d+)\), Fizzygum-tests (\d+) \(budget (\d+)\)/.exec(control.out);
    const over = (count, budget) => (m ? Number(budget) - Number(count) + 1 : 1);
    const unmarked = {};
    for (let k = 0; k < over(m && m[1], m && m[2]); k++) unmarked[`BiteProofUnmarkedClass${k}.coffee`] = text([`class BiteProofUnmarkedClass${k}`, '', `  plain: -> ${k}`]);
    for (let k = 0; k < over(m && m[3], m && m[4]); k++) unmarked[`harness/BiteProofHarnessUnmarkedClass${k}.coffee`] = text([`class BiteProofHarnessUnmarkedClass${k}`, '', `  plain: -> ${k}`]);
    return [{
      label: 'every form rule, each file planting one',
      plants: { 'BiteProofMisplaced.coffee': MISPLACED, 'harness/BiteProofHarnessMisplaced.coffee': HARNESS_MISPLACED,
        'boot/BiteProofBoot.coffee': NOT_A_CLASS, 'BiteProofMalformed.coffee': MALFORMED, 'BiteProofEmpty.coffee': EMPTY,
        'BiteProofUnmarked.coffee': UNMARKED_METHOD, 'BiteProofStash.coffee': STASH },
      expect: {
        MARKER_MISPLACED: /^  MARKER_MISPLACED  BiteProofMisplaced\.coffee:1  "#: accessing" — above the class line: the meta-system reads it as BiteProofMisplaced's comment$/m,
        CATEGORY_NAME_MALFORMED: /^  CATEGORY_NAME_MALFORMED  BiteProofMalformed\.coffee:5  "#: Accessing" — no marker/m,
        EMPTY_CATEGORY: /^  EMPTY_CATEGORY  BiteProofEmpty\.coffee:3  "accessing" has no instance method under it before the next marker \(line 4\)$/m,
        MARKED_CLASS_UNMARKED_METHOD: /^  MARKED_CLASS_UNMARKED_METHOD  BiteProofUnmarked\.coffee:3  BiteProofUnmarked\.above stands above BiteProofUnmarked's first marker \(line 5\)/m,
        STASH_HOLDS_CODE: /^  STASH_HOLDS_CODE  BiteProofStash\.coffee:1  1 line\(s\) of code above the class line, in no member's source/m,
      },
      advised: ['MARKER_MISPLACED', 'CATEGORY_NAME_MALFORMED', 'EMPTY_CATEGORY', 'MARKED_CLASS_UNMARKED_METHOD', 'STASH_HOLDS_CODE'],
      lines: [
        /^  MARKER_MISPLACED  BiteProofMisplaced\.coffee:7  "#: drawing" — at 4 column\(s\), not the member column's two spaces: inside BiteProofMisplaced\.first's code/m,
        /^  MARKER_MISPLACED  BiteProofMisplaced\.coffee:9  "#: testing" — at 0 column\(s\), not the member column's two spaces: inside BiteProofMisplaced\.first's code/m,
        /^  MARKER_MISPLACED  harness\/BiteProofHarnessMisplaced\.coffee:5  "#: drawing" — at 4 column\(s\)/m,
        /^  MARKER_MISPLACED  boot\/BiteProofBoot\.coffee:2  "#: accessing" — in a file that holds no class/m,
        /^  CATEGORY_NAME_MALFORMED  BiteProofMalformed\.coffee:7  "#:accessing" — no marker/m,
        /^  CATEGORY_NAME_MALFORMED  BiteProofMalformed\.coffee:9  "#: drag {2}and drop" — no marker/m,
        /^  CATEGORY_NAME_MALFORMED  BiteProofMalformed\.coffee:11  "#: extends things" — no marker/m,
        /^  CATEGORY_NAME_MALFORMED  BiteProofMalformed\.coffee:13  "#: extendsfoo" — no marker/m,
        /^  EMPTY_CATEGORY  BiteProofEmpty\.coffee:7  "testing" has no instance method under it before the next marker \(line 11\)$/m,
        /^  EMPTY_CATEGORY  BiteProofEmpty\.coffee:13  "lifecycle" has no instance method under it before BiteProofEmpty's end$/m,
        /^  STASH_HOLDS_CODE  BiteProofStash\.coffee:3  1 line\(s\) of code among the lines above BiteProofStash\.first, in no member's source/m,
        /^  STASH_HOLDS_CODE  BiteProofStash\.coffee:9  1 line\(s\) of code among the lines above BiteProofStash\.second,/m,
        /^  STASH_HOLDS_CODE  BiteProofStash\.coffee:15  2 line\(s\) of code among the lines above BiteProofStash\.show,/m,
        // every line above, and no other: 5 misplaced, 5 malformed, 3 empty, 1 unmarked method, 4 runs of code
        /^\[method-categories\] FAIL — 18 problem\(s\):$/m,
      ],
      // no planted file trips a rule it does not plant
      absent: [
        otherRuleOn('MARKER_MISPLACED', 'BiteProofMisplaced'), otherRuleOn('MARKER_MISPLACED', 'BiteProofHarnessMisplaced'),
        otherRuleOn('MARKER_MISPLACED', 'BiteProofBoot'), otherRuleOn('CATEGORY_NAME_MALFORMED', 'BiteProofMalformed'),
        otherRuleOn('EMPTY_CATEGORY', 'BiteProofEmpty'), otherRuleOn('MARKED_CLASS_UNMARKED_METHOD', 'BiteProofUnmarked'),
        otherRuleOn('STASH_HOLDS_CODE', 'BiteProofStash'),
      ],
    }, {
      label: 'the unmarked classes over the budget, in src and in the harness',
      plants: unmarked,
      expect: { UNMARKED_CLASSES_ABOVE_BUDGET: /^  UNMARKED_CLASSES_ABOVE_BUDGET  Fizzygum: \d+ classes hold an instance method and name no category \(budget \d+\)$/m },
      advised: ['UNMARKED_CLASSES_ABOVE_BUDGET'],
      lines: [/^  UNMARKED_CLASSES_ABOVE_BUDGET  Fizzygum-tests: \d+ classes hold an instance method and name no category \(budget \d+\)$/m],
    }, {
      // measured FIRST: a parse that keeps no categories makes the run INVALID before any rule is judged, a misplaced
      // marker beside it
      label: 'a parse that keeps no categories, beside a misplaced marker',
      plants: { 'BiteProofMisplaced.coffee': MISPLACED },
      edits: [['meta/Class.coffee', /^    Object\.assign parsed, notes$/m, '    parsed']],
      exit: 2,
      lines: [/^\[method-categories\] ERROR — the meta-compiler's parse of \S+ keeps no categories/m],
      absent: [/MARKER_MISPLACED/],
    }, {
      label: "a parse giving no member its marker's category: the lines and the parse disagree",
      plants: { 'BiteProofMarked.coffee': MARKED, 'BiteProofUnmarked.coffee': UNMARKED_METHOD },
      edits: [['meta/Class.coffee', /^        category = marker$/m, '        category = ""']],
      exit: 2,
      lines: [/^\[method-categories\] ERROR — BiteProofMarked\.coffee:11: BiteProofMarked\.sizeOf stands under the marker "accessing" by its lines and in the category "" by the parse/m],
      absent: [/MARKED_CLASS_UNMARKED_METHOD/],
    }, {
      label: "Widget recording no functionLiteralReading, beside a method above a marked class's first marker",
      plants: { 'BiteProofUnmarked.coffee': UNMARKED_METHOD },
      edits: [['basic-widgets/Widget.coffee', /^  @functionLiteralReading: /m, '  @biteProofReadingMoved: ']],
      exit: 2,
      lines: [/^\[method-categories\] ERROR — Widget records no class-side functionLiteralReading/m],
      absent: [/MARKED_CLASS_UNMARKED_METHOD/],
    }];
  },
  // a tree one UNDER its budget passes, saying so (prove-rules' runs each fail, so this run is the proof's own): the
  // first class marked, its budget not yet lowered, fails no build
  after: (t, { tree, control }) => {
    const label = 'a tree one under the Fizzygum budget passes: exit 0, OK, `-- UNDER` and the NOTE naming the lower count, no rule, no advice';
    const m = /Fizzygum (\d+) \(budget (\d+)\)/.exec(control.out);
    const unmarked = anUnmarkedClassIn(tree.dir);
    if (!m || !unmarked) {
      t.check(false, label, m ? 'the copy holds no src class the budget counts, to take out' : 'the control printed no Fizzygum count');
      return;
    }
    const n = Number(m[1]) - 1;
    const rel = path.relative(tree.dir, unmarked);
    tree.unplant(rel);
    const r = runGate(GATE, tree.dir, { args: ['--tests-repo=' + tree.testsRepo] });
    tree.reset();
    t.check(r.status === 0 && !r.rules && !(r.advised && r.advised.size) && /^\[method-categories\] OK/m.test(r.out) &&
      PASSING_SUMMARY.test(r.out) && new RegExp(`Fizzygum ${n} \\(budget ${m[2]}\\), .* -- UNDER$`, 'm').test(r.out) &&
      new RegExp(`^ {2}NOTE Fizzygum holds ${n} classes with an instance method and no category: lower UNMARKED_CLASSES_BUDGET\\.fizzygum to ${n} here`, 'm').test(r.out),
      label, `${rel} taken out, the count expected ${n} — ${r.why}`);
  },
});

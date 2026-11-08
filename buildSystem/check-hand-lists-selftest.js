'use strict';
// check-hand-lists-selftest.js — check-hand-lists.js's engine on an in-memory corpus, each direction both ways:
// every list state, every marker problem, the controls that keep both verdicts non-vacuous, and the
// absent-tests-repo NOTE rule. Run by buildSystem/run-selftests.js on every build.

const path = require('path');
const { analyse, evaluate, guardTokensOf, gateFileNames, harvestUniverse, preview, LANG_OF_EXT } = require('./check-hand-lists');
const t = require('./lib/selftest-verdict').cases('hand-lists');

function fail(msg) { console.error(`[hand-lists] self-test ERROR — ${msg}`); process.exit(2); }
// The corpus is made of exactly what the gate hunts, which is why the gate never scans this file. Every list
// the engine finds in it, and every marker problem, must be one the expectations name — an unexpected
// one fails too — so a tokenizer that finds nothing cannot pass the cases that expect a pass.

const CORPUS = [
  { rel: 'corpus/unsanctioned-classes.coffee', text: [
    'class CorpusA',
    '  @things: [',
    '    "Widget"      # the base',
    '    # an interleaved comment line',
    '    "PanelWdgt",',
    '    "FrameWdgt"',
    '  ]',
    '  # prose quoting a list opens none: ["Widget", "PanelWdgt"]',
    '  @interpolated: ["#{x} Widget", "Widget", "MenuWdgt"]',
    '  @afterRegex: /#/.test(x) and ["Widget", "MenuWdgt"]',
  ] },
  { rel: 'corpus/unsanctioned-members.js', text: [
    "const VERBS = [",
    "  'fooField', // a trailing comment",
    "  /* a block comment */ 'barMethod',",
    "  'bazKey',",
    "];",
    "// prose quoting a list opens none: ['fooField', 'barMethod']",
    "/* nor in a block comment:",
    " * ['fooField', 'barMethod'] */",
    "const URLS = ['http://example', 'Widget', 'PanelWdgt'];",
  ] },
  { rel: 'corpus/declaration.coffee', text: [
    'class CorpusC',
    '  @serializationTransients: [',
    '    "fooField"',
    '    "barMethod"',
    '  ]',
    '  requiredParts: ["Widget", "MenuWdgt"]',
    '  @notADeclarationKey: ["fooField", "barMethod"]',
    '  someMethod: ->',
    '    @serializationTransients: ["fooField", "bazKey"]',
  ] },
  { rel: 'corpus/sanctioned-gate-file.js', text: [
    "// The sweep below reads these.",
    "// hand-list-sanctioned: check-dead-methods.js fails when one of these",
    "// names stops being defined",
    "const SANCTIONED_BY_FILE = ['fooField', 'quxVerb'];",
    "const SANCTIONED_INLINE = ['barMethod', 'bazKey'];   // hand-list-sanctioned: SystemTest_corpusFixture fails without them",
  ] },
  { rel: 'corpus/sanctioned-token.coffee', text: [
    'class CorpusD',
    '  # hand-list-sanctioned: the rig fails CORPUS_GUARD_TOKEN on a name it cannot find',
    '  @kept: ["Widget", "MenuWdgt"]',
    '  # hand-list-sanctioned: ONLY_IN_THIS_SANCTION fails, which nothing else says',
    '  @selfVouched: ["Widget", "PanelWdgt"]',
  ] },
  { rel: 'corpus/token-emitter.js', text: [
    "console.error('CORPUS_GUARD_TOKEN: a name the rig could not find');",
  ] },
  { rel: 'corpus/sanctions-wrong.js', text: [
    "// hand-list-sanctioned: trust me",
    "const TRUSTED = ['fooField', 'barMethod'];",
    "// hand-list-sanctioned: check-no-such-gate.js fails",
    "const NO_SUCH_GATE = ['fooField', 'bazKey'];",
    "// hand-list-sanctioned:",
    "const EMPTY_MARKED = ['quxVerb', 'bazKey'];",
  ] },
  { rel: 'corpus/separated.js', text: [
    "// hand-list-sanctioned: check-dead-methods.js fails on a stale name",
    "const unrelated = 1;",
    "const SEPARATED = ['fooField', 'barMethod'];",
  ] },
  { rel: 'corpus/separated.coffee', text: [
    'class CorpusF',
    '  # hand-list-sanctioned: check-dead-methods.js fails on a stale name',
    '',
    '  @blankSeparated: ["Widget", "FrameWdgt"]',
    '  # hand-list-sanctioned: check-dead-methods.js fails on a stale name',
    '  @colours: ["red", "green", "blue"]',
    '  # hand-list-sanctioned: check-dead-methods.js fails on a stale name',
    '  @serializationTransients: ["fooField", "barMethod"]',
  ] },
  { rel: 'corpus/proportions.js', text: [
    "const MOSTLY_DATA = ['Widget', 'PanelWdgt', 'alpha', 'beta', 'gamma'];",
    "const EXACTLY_HALF = ['Widget', 'fooField', 'alpha', 'beta'];",
    "const ONE_NAME = ['Widget', 'alpha'];",
  ] },
  { rel: 'corpus/quoted-marker.js', text: [
    "// Prose quoting the syntax is no marker: write `hand-list-sanctioned: <what fails>` above a list,",
    "// or \"hand-list-sanctioned: <what fails>\" in a string.",
    "const COLOURS = ['red', 'green', 'Widget'];",
  ] },
  { rel: 'corpus/python.py', text: [
    '# hand-list-sanctioned: check-dead-methods.js fails on a stale name',
    'PY_NAMES = ["Widget", "MenuWdgt"]',
    'PY_BARE = ["FrameWdgt", "PanelWdgt"]  # the comment on the line is no marker',
  ] },
  // A guard must RUN: one that exists and nothing runs can never fail. The corpus's run set (main, below) holds
  // check-dead-methods.js and every file but unrun-emitter.js; corpus-unrun-rig.js exists and never runs.
  { rel: 'corpus/never-run.js', text: [
    "// hand-list-sanctioned: corpus-unrun-rig.js fails on a stale name",
    "const UNRUN_FILE = ['fooField', 'barMethod'];",
    "// hand-list-sanctioned: CORPUS_UNRUN_TOKEN fails on a stale name",
    "const UNRUN_TOKEN = ['bazKey', 'quxVerb'];",
    "// hand-list-sanctioned: corpus-unrun-rig.js, and check-dead-methods.js, fail on a stale name",
    "const ONE_RUNS = ['fooField', 'quxVerb'];",
  ] },
  { rel: 'corpus/unrun-emitter.js', text: [
    "console.error('CORPUS_UNRUN_TOKEN: a name the never-run rig could not find');",
  ] },
  // guard (c) is a token EMITTED — in a string, in code: one named only in a comment, or only as a constant's name,
  // is no failure anyone sees
  { rel: 'corpus/token-not-emitted.js', text: [
    "// CORPUS_COMMENT_TOKEN is only ever named in this comment",
    "const CORPUS_IDENT_TOKEN = 1;",
    "// hand-list-sanctioned: CORPUS_COMMENT_TOKEN fails on a stale name",
    "const BY_COMMENT_TOKEN = ['fooField', 'barMethod'];",
    "// hand-list-sanctioned: CORPUS_IDENT_TOKEN fails on a stale name",
    "const BY_IDENT_TOKEN = ['bazKey', 'quxVerb'];",
  ] },
];

// [file, a substring unique to the list's opening line, expected state, expected kind]
const EXPECTED_LISTS = [
  ['corpus/unsanctioned-classes.coffee', '@things:', 'UNSANCTIONED', 'CLASSES'],         // multi-line, interleaved comments
  ['corpus/unsanctioned-classes.coffee', '@interpolated:', 'UNSANCTIONED', 'CLASSES'],   // a `#` inside a string opens no comment
  ['corpus/unsanctioned-classes.coffee', '@afterRegex:', 'UNSANCTIONED', 'CLASSES'],     // …nor one inside a regex
  ['corpus/unsanctioned-members.js', 'const VERBS', 'UNSANCTIONED', 'MEMBERS'],          // `//` and block comments between items
  ['corpus/unsanctioned-members.js', 'const URLS', 'UNSANCTIONED', 'CLASSES'],           // a `//` inside a string opens no comment
  ['corpus/declaration.coffee', '@serializationTransients: [', 'DECLARATION', 'MEMBERS'],
  ['corpus/declaration.coffee', 'requiredParts:', 'DECLARATION', 'CLASSES'],
  ['corpus/declaration.coffee', '@notADeclarationKey:', 'UNSANCTIONED', 'MEMBERS'],      // a key the table does not hold
  ['corpus/declaration.coffee', '    @serializationTransients:', 'UNSANCTIONED', 'MEMBERS'], // not at the class-body indent
  ['corpus/sanctioned-gate-file.js', 'SANCTIONED_BY_FILE', 'SANCTIONED', 'MEMBERS'],    // guard (a), block above, wrapped text
  ['corpus/sanctioned-gate-file.js', 'SANCTIONED_INLINE', 'SANCTIONED', 'MEMBERS'],     // guard (b), on the opening line
  ['corpus/sanctioned-token.coffee', '@kept:', 'SANCTIONED', 'CLASSES'],                // guard (c), `#` marker
  ['corpus/sanctioned-token.coffee', '@selfVouched:', 'SANCTIONED', 'CLASSES'],         // …whose token only it says: no guard
  ['corpus/sanctions-wrong.js', 'TRUSTED', 'SANCTIONED', 'MEMBERS'],
  ['corpus/sanctions-wrong.js', 'NO_SUCH_GATE', 'SANCTIONED', 'MEMBERS'],
  ['corpus/sanctions-wrong.js', 'EMPTY_MARKED', 'SANCTIONED', 'MEMBERS'],
  ['corpus/separated.js', 'SEPARATED', 'UNSANCTIONED', 'MEMBERS'],                      // a code line breaks the block
  ['corpus/separated.coffee', '@blankSeparated:', 'UNSANCTIONED', 'CLASSES'],           // a blank line breaks the block
  ['corpus/separated.coffee', '@colours:', '-', 'other'],
  ['corpus/separated.coffee', '@serializationTransients:', 'DECLARATION', 'MEMBERS'],
  ['corpus/proportions.js', 'MOSTLY_DATA', '-', 'other'],                               // 2 names of 5: under half
  ['corpus/proportions.js', 'EXACTLY_HALF', 'UNSANCTIONED', 'MIXED'],                   // 2 of 4: half is enough
  ['corpus/proportions.js', 'ONE_NAME', '-', 'other'],                                  // half, but a lone name
  ['corpus/quoted-marker.js', 'COLOURS', '-', 'other'],                                 // …and no SANCTION_STALE above it
  ['corpus/python.py', 'PY_NAMES', 'SANCTIONED', 'CLASSES'],
  ['corpus/python.py', 'PY_BARE', 'UNSANCTIONED', 'CLASSES'],
  ['corpus/never-run.js', 'UNRUN_FILE', 'SANCTIONED', 'MEMBERS'],                       // sanctioned, its guard never runs
  ['corpus/never-run.js', 'const UNRUN_TOKEN', 'SANCTIONED', 'MEMBERS'],
  ['corpus/never-run.js', 'ONE_RUNS', 'SANCTIONED', 'MEMBERS'],                         // the control: one guard that runs is enough
  ['corpus/token-not-emitted.js', 'BY_COMMENT_TOKEN', 'SANCTIONED', 'MEMBERS'],
  ['corpus/token-not-emitted.js', 'BY_IDENT_TOKEN', 'SANCTIONED', 'MEMBERS'],
];
// [file, a substring unique to the marker's line, expected problem]
const EXPECTED_PROBLEMS = [
  ['corpus/sanctioned-token.coffee', 'ONLY_IN_THIS_SANCTION', 'SANCTION_NAMES_NO_GUARD'],
  ['corpus/sanctions-wrong.js', 'trust me', 'SANCTION_NAMES_NO_GUARD'],
  ['corpus/sanctions-wrong.js', 'check-no-such-gate.js', 'SANCTION_NAMES_NO_GUARD'],
  ['corpus/sanctions-wrong.js', 'hand-list-sanctioned', 'SANCTION_EMPTY', 3],          // the bare marker
  ['corpus/separated.js', 'hand-list-sanctioned', 'SANCTION_STALE'],
  ['corpus/separated.coffee', 'hand-list-sanctioned', 'SANCTION_STALE', 1],             // above the blank line
  ['corpus/separated.coffee', 'hand-list-sanctioned', 'SANCTION_STALE', 2],             // above a non-name list
  ['corpus/separated.coffee', 'hand-list-sanctioned', 'SANCTION_STALE', 3],             // above a declaration
  ['corpus/never-run.js', 'corpus-unrun-rig.js fails', 'SANCTION_GUARD_NEVER_RUNS'],    // guard (a) exists, never runs
  ['corpus/never-run.js', 'CORPUS_UNRUN_TOKEN', 'SANCTION_GUARD_NEVER_RUNS'],           // guard (c) emitted only by an unrun file
  ['corpus/token-not-emitted.js', 'hand-list-sanctioned: CORPUS_COMMENT_TOKEN', 'SANCTION_NAMES_NO_GUARD'],   // named in a comment only
  ['corpus/token-not-emitted.js', 'hand-list-sanctioned: CORPUS_IDENT_TOKEN', 'SANCTION_NAMES_NO_GUARD'],     // a constant's name only
];

function main() {
  const universe = { classes: new Set(['Widget', 'PanelWdgt', 'FrameWdgt', 'MenuWdgt']),
                     members: new Set(['fooField', 'barMethod', 'bazKey', 'quxVerb']) };
  const files = CORPUS.map(c => {
    const ext = path.extname(c.rel);
    return { rel: c.rel, repo: 'fizzygum', ext, ...analyse(c.text.join('\n'), LANG_OF_EXT[ext]) };
  });
  const gateFiles = gateFileNames(false);
  if (!gateFiles.has('check-dead-methods.js')) fail('self-test: the real tree has no buildSystem/check-dead-methods.js to resolve guard (a) against');
  // two universes: what EXISTS (the real buildSystem's files plus a fictional rig) and what RUNS within it
  const testDirs = new Set(['SystemTest_corpusFixture']);
  const exists = { gateFiles: new Set([...gateFiles, 'corpus-unrun-rig.js']), testDirs, tokens: guardTokensOf(files) };
  const runs = { gateFiles: new Set(['check-dead-methods.js']), testDirs,
                 tokens: guardTokensOf(files.filter(f => f.rel !== 'corpus/unrun-emitter.js')) };
  const guards = { exists, runs, complete: true, runsKnown: true };
  const { lists, problems } = evaluate(files, universe, guards);
  const check = (pass, msg) => t.check(pass, msg);
  const lineOf = (rel, needle, nth = 1) => {
    const text = CORPUS.find(c => c.rel === rel).text;
    let seen = 0;
    for (let i = 0; i < text.length; i++) if (text[i].includes(needle) && ++seen === nth) return i + 1;
    fail(`self-test corpus: no line ${nth} holding '${needle}' in ${rel}`);
  };
  const matchedLists = new Set();
  for (const [rel, needle, state, kind] of EXPECTED_LISTS) {
    const line = lineOf(rel, needle);
    const got = lists.filter(l => l.file.rel === rel && l.line === line);
    got.forEach(l => matchedLists.add(l));
    const desc = got.map(l => `${l.state}/${l.kind}`).join(' ') || 'NOT FOUND';
    check(got.length === 1 && got[0].state === state && got[0].kind === kind, `${rel}:${line} (${needle}) -> ${desc} (expected ${state}/${kind})`);
  }
  for (const l of lists.filter(x => !matchedLists.has(x))) check(false, `unexpected list ${l.file.rel}:${l.line} [${preview(l.items)}] -> ${l.state}/${l.kind}`);
  const matchedProblems = new Set();
  for (const [rel, needle, token, nth] of EXPECTED_PROBLEMS) {
    const line = lineOf(rel, needle, nth);
    const got = problems.filter(p => p.file.rel === rel && p.line === line);
    got.forEach(p => matchedProblems.add(p));
    check(got.length === 1 && got[0].token === token, `${rel}:${line} marker -> ${got.map(p => p.token).join(' ') || 'no problem'} (expected ${token})`);
  }
  for (const p of problems.filter(x => !matchedProblems.has(x))) check(false, `unexpected problem ${p.token} at ${p.file.rel}:${p.line}`);
  // CONTROL: the corpus is not vacuous — the engine flags something, accepts something, and the same lists
  // under an EMPTY universe are certified wholesale, which is why the gate exits 2 on one.
  const flagged = lists.filter(l => l.state === 'UNSANCTIONED').length + problems.length;
  const accepted = lists.filter(l => l.state === 'DECLARATION' || l.state === 'SANCTIONED').length;
  check(flagged > 0 && accepted > 0, `control: the corpus both fails (${flagged}) and passes (${accepted}) — neither verdict is vacuous`);
  const empty = evaluate(files, { classes: new Set(), members: new Set() }, guards);
  check(empty.lists.every(l => !l.isName) && empty.lists.length === lists.length,
    `control: an empty universe finds the same ${empty.lists.length} lists and calls none of them a name list`);
  // WITHOUT THE TESTS REPO (guards.complete false, and here the universe lacking `MenuWdgt` as the absent
  // harness's classes would be lacking): a sanction above a list that now reads as data, or naming no guard
  // this checkout can see, is a NOTE; one above a line where no list opens stays a failure.
  const partial = evaluate(files, { classes: new Set(['Widget', 'PanelWdgt', 'FrameWdgt']), members: universe.members },
    { ...guards, complete: false });
  const tokenAt = (r, rel, needle, nth) => {
    const line = lineOf(rel, needle, nth);
    return r.problems.filter(p => p.file.rel === rel && p.line === line).map(p => p.token + (p.note ? '(note)' : '')).join(' ') || 'none';
  };
  for (const [rel, needle, nth, want] of [
    ['corpus/sanctioned-token.coffee', 'CORPUS_GUARD_TOKEN', 1, 'SANCTION_UNVERIFIED(note)'],  // its list names MenuWdgt
    ['corpus/sanctions-wrong.js', 'trust me', 1, 'SANCTION_UNVERIFIED(note)'],
    ['corpus/separated.js', 'hand-list-sanctioned', 1, 'SANCTION_STALE'],
  ]) {
    const got = tokenAt(partial, rel, needle, nth);
    check(got === want, `tests repo absent: ${rel} marker -> ${got} (expected ${want})`);
  }
  // WITHOUT THE UMBRELLA'S fg (guards.runsKnown false): the commit-point legs cannot be read, so a guard that
  // exists and is not seen to run may run in a leg — a NOTE, never a failure; a guard nothing names still fails.
  const noFg = evaluate(files, universe, { ...guards, runsKnown: false });
  for (const [rel, needle, nth, want] of [
    ['corpus/never-run.js', 'corpus-unrun-rig.js fails', 1, 'SANCTION_UNVERIFIED(note)'],
    ['corpus/never-run.js', 'CORPUS_UNRUN_TOKEN', 1, 'SANCTION_UNVERIFIED(note)'],
    ['corpus/sanctions-wrong.js', 'trust me', 1, 'SANCTION_NAMES_NO_GUARD'],
  ]) {
    const got = tokenAt(noFg, rel, needle, nth);
    check(got === want, `fg absent: ${rel} marker -> ${got} (expected ${want})`);
  }
  universeCases();
  proveTheGate();
  t.done();
}

// THE UNIVERSE a list's names are checked against: every class (a file's name) and every class-body key, read past
// a heregex holding `'''` and never from a heredoc's lines.
function universeCases() {
  const fs = require('fs'), os = require('os');
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'hand-lists-universe-'));
  const file = path.join(dir, 'CorpusUniverse.coffee');
  fs.writeFileSync(file, ['class CorpusUniverse',
    "  corpusPattern: ///'''///",
    '  corpusAfterPattern: -> 1',
    '  corpusDoc: """',
    '  corpusNotAKey: 1',
    '  """',
    '  @corpusAfterDoc: 2', ''].join('\n'));
  const { classes, members } = harvestUniverse([file]);
  fs.rmSync(dir, { recursive: true, force: true });
  const got = [...classes, ...members].join(',');
  t.check(got === 'CorpusUniverse,corpusPattern,corpusAfterPattern,corpusDoc,corpusAfterDoc',
    "the universe: a key after a heregex holding ''' is a key, a heredoc's line is none", got);
}

// ---- the REAL gate on a planted src copy ---------------------------------------------------------------------------
// The engine cases above judge lists and sanctions in memory; here the gate itself — its walk of both halves, the name
// universe, what-runs' run set, the ratchet, the exit — runs on a src copy carrying the plants (lib/planted-src.js),
// and in --files mode on a planted file. The guard that never runs is read from lib/what-runs.js, not named here.
function proveTheGate() {
  const fs = require('fs');
  const os = require('os');
  const { proveGate } = require('./lib/planted-src');
  const whatRuns = require('./lib/what-runs');
  const ran = whatRuns.runSet().files;
  const neverRun = whatRuns.scriptFiles().map((f) => [f, path.basename(f)])
    .filter(([f, b]) => !ran.has(f) && f.includes(`${path.sep}buildSystem${path.sep}`) && /^[\w.-]+\.js$/.test(b) && !/selftest/.test(b))[0][1];
  const given = fs.mkdtempSync(path.join(os.tmpdir(), 'check-hand-lists-selftest-'));
  process.on('exit', () => fs.rmSync(given, { recursive: true, force: true }));
  fs.writeFileSync(path.join(given, 'bite-proof-list.js'), "const D = ['Widget', 'PanelWdgt'];\n");
  // a planted .coffee printing the token its own sanction names: it must not vouch for itself
  fs.writeFileSync(path.join(given, 'BiteProofSelfVouch.coffee'), ['class BiteProofSelfVouch',
    '  # hand-list-sanctioned: BITE_PROOF_SELF_TOKEN', '  @bpNames: ["Widget", "PanelWdgt"]', '  bpSay: -> console.error "BITE_PROOF_SELF_TOKEN"', ''].join('\n'));
  const cls = (name, ...body) => [`class ${name}`, ...body, ''].join('\n');
  proveGate({
    name: 'hand-lists',
    cases: t,
    gate: path.join(__dirname, 'check-hand-lists.js'),
    pass: /^\[hand-lists\] OK — /m,
    control: {
      plants: {
        'BiteProofHandListsOk.coffee': cls('BiteProofHandListsOk',
          '  @serializationTransients: ["Widget", "PanelWdgt"]',
          '  @bpSanctioned: ["Widget", "PanelWdgt"]   # hand-list-sanctioned: check-dead-methods.js',
          '  @bpData: ["red", "green", "Widget"]',
          '  @bpLone: ["Widget"]',
          '  # @bpInAComment: ["Widget", "PanelWdgt"]'),
      },
    },
    runs: [{
      label: 'a list over the baseline, four wrong sanctions',
      plants: {
        'BiteProofHandLists.coffee': cls('BiteProofHandLists',
          '  @bpThings: ["Widget", "PanelWdgt"]',
          '  # hand-list-sanctioned:',
          '  @bpEmpty: ["Widget", "PanelWdgt"]',
          '  # hand-list-sanctioned: check-dead-methods.js',
          '  bpNoList: 1',
          '  # hand-list-sanctioned: trust me',
          '  @bpNoGuard: ["Widget", "PanelWdgt"]',
          `  # hand-list-sanctioned: ${neverRun}`,
          '  @bpNeverRun: ["Widget", "PanelWdgt"]'),
      },
      expect: {
        OVER_BASELINE: /^  \S*BiteProofHandLists\.coffee:2  \[Widget, PanelWdgt\]$/m,
        SANCTION_EMPTY: /^  SANCTION_EMPTY  \S*BiteProofHandLists\.coffee:3  /m,
        SANCTION_STALE: /^  SANCTION_STALE  \S*BiteProofHandLists\.coffee:5  /m,
        SANCTION_NAMES_NO_GUARD: /^  SANCTION_NAMES_NO_GUARD  \S*BiteProofHandLists\.coffee:7  /m,
        SANCTION_GUARD_NEVER_RUNS: new RegExp(`^  SANCTION_GUARD_NEVER_RUNS  \\S*BiteProofHandLists\\.coffee:9  [\\s\\S]*?\\(named, never run: ${neverRun.replace(/\./g, '\\.')}\\)`, 'm'),
      },
      absent: [/BiteProofHandListsOk/],
    }, {
      label: '--files: a planted list, and a plant that cannot vouch for itself',
      args: ['--files', path.join(given, 'bite-proof-list.js'), path.join(given, 'BiteProofSelfVouch.coffee')],
      expect: {
        UNSANCTIONED_NAME_LIST: /^  UNSANCTIONED_NAME_LIST  \S*bite-proof-list\.js:1  \[Widget, PanelWdgt\]$/m,
        SANCTION_GUARD_NEVER_RUNS: /^  SANCTION_GUARD_NEVER_RUNS  \S*BiteProofSelfVouch\.coffee:2  /m,
      },
    }],
  });
}

main();

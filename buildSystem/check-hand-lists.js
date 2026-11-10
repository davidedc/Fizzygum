#!/usr/bin/env node
'use strict';
// check-hand-lists.js — build gate: a STRING LIST that names classes or members declared elsewhere is
// a DECLARATION, carries a SANCTION naming the guard that fails when it goes stale, or is COUNTED
// against a per-repo ratchet that only falls.
//
// THE FAILURE MODE. A list that repeats names declared somewhere else is a second source of truth with
// nothing holding it to the first. `Serializer.WORLD_APP_SLOTS` repeated five of six one-window apps'
// world fields, and the sixth app was silently treated differently by every reader; the serialization
// rig's COLLECTIONS and DRAG_SLOTS each fell behind the world within weeks. The worst of these live in
// the CHECKERS: a gate or rig that hand-lists what the framework declares keeps running when the
// framework grows, matches less, and stays green — it certifies what it never looked at. The cure is to
// DERIVE the names where they are declared, or to ASSERT the list against its source both ways
// (docs/architecture/lint-and-static-checks.md §5, "The names a gate keys on are DERIVED, or ASSERTED";
// docs/archive/hand-kept-lists-plan.md §6.2). This gate is the standing guard: it makes every NEW list of
// that shape visible, and holds the unexamined ones to a count that can only fall.
//
// WHY A MULTI-LINE TOKENIZER, NOT A STINK. check-stinks.js reads one line at a time, and the lists that
// rot are written one name per line with comments between the names, so a per-line rule sees none of
// them. From every `[` this reads ahead ACROSS lines: string literals separated by commas, whitespace
// and comments (`#` in .coffee/.py; `//` and block comments in .js) until `]` — a STRING LIST — or
// anything else, which ends the attempt (a list holding any non-literal is not a pure string list).
// A `[` inside a comment opens nothing: prose may quote a list.
//
// WHAT IT SCANS. The Fizzygum half: src/**/*.coffee and buildSystem/**/*.{js,py}. The tests half, when
// the sibling Fizzygum-tests repo is present: scripts/**/*.js and Automator-and-test-harness-src/**/*.coffee.
// The .coffee files are the compiled sources as lib/source-files.js lists them (srcFiles, harnessFiles: every
// one, refusing a symlink); the .js/.py files are the tooling's own (lib/what-runs.js scriptFiles: never a dot entry
// such as `.scratch`, a node_modules or a __pycache__, a symlink refused). The tests repo's tests/ is skipped —
// macro sources are test CONTENT, held by that repo's own gates. Its self-test file
// (check-hand-lists-selftest.js) is skipped as well: its corpus is made of exactly the lists this hunts, so
// scanning it would count the fixtures.
// Without the tests repo the tests half SKIPS and says so, as check-dead-methods.js and
// check-part-edges.js do.
//
// THE NAME UNIVERSE. CLASS names: the basename of every .coffee file under Fizzygum/src and the harness
// (one class per file, filename = class name; src/boot's files count too, and name boot sources).
// MEMBER names: every class-body key at the class-body indent (`  name:` / `  @name:`) in the same files,
// plus a mixin's member keys at the indent its onceAddedClassProperties hash locks
// (lib/coffee-method-header.js mixinMemberIndent: what a mixin puts on a widget is a member like any
// other). Lines inside a heredoc declare nothing — a code sample in a string is not a class body. This
// harvest is its own because no shared one answers this question: lib/name-definitions.js and
// lib/coffee-method-header.js see CALLABLE members only (a method header, a function), while the lists
// that rotted named FIELDS (world collections, drag-embed slots); lib/install-edges.js
// reads this same key shape privately, for one support class at a time. An EMPTY universe classifies
// nothing as a name and so certifies everything: exit 2.
//
// WHAT A NAME LIST IS. A string list with at least TWO items that are class or member names, those being
// at least HALF of its items. Two, because a lone name is an index or a single fact, not a mirror. Half,
// counted across both kinds together, because a rotting list mixes a few data words in among its names:
// a 60%-per-kind rule (the census this gate grew out of) missed three such lists, and a bare "two names"
// rule flags data lists that merely contain two common words (heap-snapshot field names, CSS keywords).
// The census reports the kind as CLASSES, MEMBERS or MIXED.
//
// EACH NAME LIST HAS EXACTLY ONE STATE.
//   - DECLARATION: the value of a recognised class-body key on the list's opening line (DECLARATION_KEYS
//     below, each with its reason) — a class stating its OWN facts, which is a single source.
//   - SANCTIONED: a `hand-list-sanctioned: <text>` marker in a LINE comment (`#` in .coffee/.py, `//` in
//     .js), either on the list's opening line (the line holding its `[`) or in the contiguous comment
//     block directly above that line — a code line or a blank line in between breaks the block. The text
//     says what fails if the list goes stale, and must NAME A REAL GUARD (below). A marker written right
//     after a backtick or a quote is prose QUOTING the syntax, as this header does, and sanctions nothing.
//   - UNSANCTIONED: everything else. These are what the ratchet counts.
//
// HOW A SANCTION'S GUARD IS RESOLVED — mechanically, and the guard must RUN, because a guard nothing runs
// can never fail (docs/archive/unrun-checks-plan.md). At least one of:
//   (a) the basename of a gate or rig file that RUNS: one lib/what-runs.js reaches from the build
//       (build_it_please.sh), a discovered self-test, or a presuite/gauntlet leg of the umbrella's fg, by an
//       invocation — never a mention. Candidates are Fizzygum/buildSystem/*.js and lib/*.js,
//       build_it_please.sh, and every .js or .sh under Fizzygum-tests/scripts. This file does not count:
//       it checks that a list is examined, never current;
//   (b) `SystemTest_<name>` naming a test (lib/tests-repo-code.js testNames) — it runs whenever the suite runner
//       (run-all-headless.js) does;
//   (c) an UPPER_SNAKE token — two or more segments joined by `_` or `-`, each starting with a letter
//       (`MENU_CONTRIBUTOR_UNSWEPT`, `TIERNAMING-UNCLASSIFIED`) — that occurs, OUTSIDE every sanction's
//       own text (so a sanction cannot vouch for itself), in a scanned file that runs: a script per (a), or
//       a world source (src, the harness) when the suite runner runs, which fails every console line led
//       by a token (Fizzygum-tests/scripts/lib/gate-tokens.js).
//   A sanction's text is the rest of its marker's line plus the comment lines below it in the same block.
//   One resolving none fails as SANCTION_NAMES_NO_GUARD, and one whose every guard exists but never runs
//   as SANCTION_GUARD_NEVER_RUNS — always, never ratcheted. A marker with no text on its own line fails as
//   SANCTION_EMPTY; one that sanctions no name list fails as SANCTION_STALE (the list moved, became a
//   declaration, or was derived away, and a marker that sanctions nothing reads to the next author as if
//   it did). ⚠ Resolution proves the guard RUNS, not that it covers the list: it makes the author name
//   what fails, which a reviewer can then check; it cannot check it for them.
//   Undecidable on this checkout, so listed UNVERIFIED in a NOTE rather than failed:
//   - without the tests repo, a Fizzygum-half sanction resolving no guard, or above a list that reads as
//     data — the guard it names may live there, and so may the harness classes that make it a name list;
//   - without the umbrella's fg (a bare clone of the repos), a sanction whose guards exist but are not
//     seen to run — they may run in a leg (`--fg=<path>` reads another fg, or none).
//   One above a line where no list opens at all is SANCTION_STALE on every checkout.
//
// THE RATCHET (the check-stinks.js idiom). BASELINE_FIZZYGUM and BASELINE_TESTS cap the UNSANCTIONED
// name lists per repo. Above its baseline a repo FAILS, printing every unsanctioned list it holds; below
// it, a NOTE asks for the baseline to be tightened here. A list leaves the count by being DERIVED from
// where its names are declared, or by being ASSERTED both ways and sanctioned naming the guard that fails.
//
// BLIND SPOTS, plainly. It sees string-list LITERALS only — not object tables keyed by names, regex
// alternations, `switch`/`when` arms, sequences of pushes, or names assembled at runtime; those mirror
// declarations just as well and are found by reading (the plan's §2). A list under half names is not a
// name list, so a mirror padded with data words passes unseen. A list opening inside a comment is prose
// and is not read. Comments and strings are told apart line by line, so the inside of a multi-line
// template literal or heredoc reads as code — lists in embedded code count, the direction that flags
// more. A marker must sit on the line holding the `[`, or in the comment block directly above it.
//
// MODES.
//   node buildSystem/check-hand-lists.js                 the gate: exit 0 clean, 1 violation, 2 operational error
//   node buildSystem/check-hand-lists.js --census [--names-only] [--min=N] [--files <path…>]
//       every string list with at least N items (default 2) — its kind, item counts (classes / members /
//       other), state, and each sanction's resolved guard (and any it names that never runs) — then exit 0:
//       a census, never a gate
//   node buildSystem/check-hand-lists.js --files <path…>  only the given files; there EVERY unsanctioned
//       name list is a violation (no ratchet), so a plant fails exactly
//   --fg=<path>  read that file as the umbrella's fg (a path that does not exist = none: the bare-clone view)
// Its self-test, an in-memory corpus showing each direction bite, is check-hand-lists-selftest.js (run by
// buildSystem/run-selftests.js on every build).

const fs = require('fs');
const path = require('path');
const { mixinMemberIndent } = require('./lib/coffee-method-header');
const { testNames } = require('./lib/tests-repo-code');
const { rejectUnknownArgs } = require('./lib/cli-args');
const { srcFiles, harnessFiles, compiledFiles, sourceRoots, SOURCE_RAILS, HARNESS_DIR } = require('./lib/source-files');
const rules = require('./lib/gate-rules').forGate(__filename);
// the four failing sanction tokens; SANCTION_UNVERIFIED is a note, never a rule
rules.declare(['SANCTION_NAMES_NO_GUARD', 'SANCTION_GUARD_NEVER_RUNS', 'SANCTION_EMPTY', 'SANCTION_STALE']);
const { runSet, scriptFiles, DEFAULT_LAYOUT: WHAT_RUNS_LAYOUT } = require('./lib/what-runs');

const FIZZYGUM = path.resolve(__dirname, '..');
const UMBRELLA = path.resolve(FIZZYGUM, '..');
const BUILD_SYSTEM = path.join(FIZZYGUM, 'buildSystem');
// main() reads the --src= / --tests-repo= rails (lib/source-files.js sourceRoots) and places the tests repo's parts
let ROOTS, HARNESS, SCRIPTS, TEST_DIRS;
const SELF = path.resolve(__filename);
const SELF_TEST_CORPUS = path.join(BUILD_SYSTEM, 'check-hand-lists-selftest.js');

// Unsanctioned name lists in Fizzygum's own src/ + buildSystem/: the four LiveCodeLang command lists in
// src/fizzytiles/LCLCodePreprocessor.coffee, whose guard is the headless preprocessor gate the open
// livecodelang-cleanup-and-extensions plan builds (its R1). Tightened as each list is derived or sanctioned.
const BASELINE_FIZZYGUM = 4;
// Unsanctioned name lists in Fizzygum-tests' scripts/ + Automator-and-test-harness-src/: none, so a new
// one fails the build until it is derived, or asserted and sanctioned.
const BASELINE_TESTS = 0;

// The class-body keys whose list value IS a declaration: the class names facts about ITSELF, and the
// code that acts on them reads them from the class, so there is no second copy to drift.
const DECLARATION_KEYS = new Map([
  ['@serializationTransients', 'the fields of its own the class tells the Serializer and Duplicator to skip, read through its class chain'],
  ['requiredParts', "the parts an app's own launch awaits before it builds (check-part-edges.js reads the same list as the app's await)"],
  ['optionalParts', "the parts an app's own launch loads when they ship, read by that same launch"],
]);

// a marker QUOTED in prose (`` `hand-list-sanctioned: …` ``, as this header writes it) is not one
const MARKER_RE = /(?<![`'"])hand-list-sanctioned:(.*)$/;
// an UPPER_SNAKE guard token, guard (c) in the header
const GUARD_TOKEN_RE = /(?<![\w-])[A-Z][A-Z0-9]*(?:[_-][A-Z][A-Z0-9]*)+(?![A-Za-z0-9])/g;
const GATE_FILE_RE = /[\w.\/-]+\.(?:js|sh)\b/g;
const SYSTEM_TEST_RE = /\bSystemTest_\w+/g;
const LANG_OF_EXT = { '.coffee': 'coffee', '.py': 'hash', '.js': 'slash' };
const hashComments = (lang) => lang === 'hash' || lang === 'coffee';   // a `#` opens a comment
const { coffeeMask } = require('./lib/coffee-mask');

function fail(msg) { console.error(`[hand-lists] ERROR — ${msg}`); process.exit(2); }

// the tooling's own files under `dir` with one of `exts` — what-runs.js scriptFiles, the one definition of them (this
// run's tests repo included, once main has read the rails; the real one before)
function toolingFiles(dir, exts) {
  const under = dir + path.sep;
  return scriptFiles({ ...WHAT_RUNS_LAYOUT, tests: ROOTS ? ROOTS.testsRepo : WHAT_RUNS_LAYOUT.tests })
    .filter(p => p.startsWith(under) && exts.some(x => p.endsWith(x)));
}

// ---- the per-file engine (pure: text in, records out — what the self-test drives) --------------------

// For each line, the column ranges that are COMMENT, the column where a LINE comment opens (-1 if none), and the
// column ranges that are STRING literals (quotes included). CoffeeScript's is lib/coffee-mask.js's (coffeeLayout);
// .py and .js are a string-aware scan that restarts on every line, .js block comments carrying across lines.
function commentLayout(lines, lang, where) {
  if (lang === 'coffee') return coffeeLayout(lines, where);
  const out = [];
  let inBlock = false;
  for (const line of lines) {
    const ranges = [], strings = [];
    let lineCommentAt = -1, quote = null, quoteFrom = -1, blockFrom = inBlock ? 0 : -1;
    for (let i = 0; i < line.length; i++) {
      const c = line[i];
      if (blockFrom >= 0) {
        if (c === '*' && line[i + 1] === '/') { ranges.push([blockFrom, i + 2]); blockFrom = -1; i++; }
        continue;
      }
      if (quote) {
        if (c === '\\') i++;
        else if (c === quote) { quote = null; strings.push([quoteFrom, i + 1]); }
        continue;
      }
      if (c === '"' || c === "'" || c === '`') { quote = c; quoteFrom = i; continue; }
      if (hashComments(lang) && c === '#') { lineCommentAt = i; break; }
      if (lang === 'slash' && c === '/' && line[i + 1] === '/') { lineCommentAt = i; break; }
      if (lang === 'slash' && c === '/' && line[i + 1] === '*') { blockFrom = i; i++; }
    }
    inBlock = blockFrom >= 0;
    if (inBlock) ranges.push([blockFrom, line.length]);
    if (lineCommentAt >= 0) ranges.push([lineCommentAt, line.length]);
    if (quote) strings.push([quoteFrom, line.length]);   // a string the line leaves open
    out.push({ ranges, lineCommentAt, strings });
  }
  return out;
}

// CoffeeScript's layout is lib/coffee-mask.js's reading (the lexer's): each run of comment, and each run of literal
// text (its quotes included) as a string.
function coffeeLayout(lines, where) {
  return coffeeMask(lines.join('\n'), where).map(({ mask }) => {
    const runs = (kind) => {
      const out = [];
      for (let k = 0; k < mask.length; k++) {
        if (mask[k] !== kind) continue;
        let j = k;
        while (j < mask.length && mask[j] === kind) j++;
        out.push([k, j]);
        k = j - 1;
      }
      return out;
    };
    const ranges = runs('cut');
    return { ranges, lineCommentAt: ranges.length ? ranges[0][0] : -1, strings: runs('str') };
  });
}

// From just after a `[`, the items of a pure string list, or null when anything other than string
// literals, separators and comments comes before its `]` (or the list is empty).
function readStringList(text, j, lang) {
  const items = [];
  for (;;) {
    while (j < text.length && /[\s,]/.test(text[j])) j++;
    if (j >= text.length) return null;
    if ((hashComments(lang) && text[j] === '#') || (lang === 'slash' && text.startsWith('//', j))) {
      while (j < text.length && text[j] !== '\n') j++;
      continue;
    }
    if (lang === 'slash' && text.startsWith('/*', j)) {
      const end = text.indexOf('*/', j + 2);
      if (end < 0) return null;
      j = end + 2;
      continue;
    }
    if (text[j] === ']') return items.length ? items : null;
    if (text[j] !== '"' && text[j] !== "'") return null;
    const q = text[j];
    let k = j + 1, s = '';
    while (k < text.length && text[k] !== q && text[k] !== '\n') {
      if (text[k] === '\\' && k + 1 < text.length) { s += text[k + 1]; k += 2; } else s += text[k++];
    }
    if (text[k] !== q) return null;
    items.push(s);
    j = k + 1;
  }
}

const isCommentLine = (lines, layout, k) =>
  k >= 0 && k < lines.length && layout[k].lineCommentAt >= 0 && lines[k].slice(0, layout[k].lineCommentAt).trim() === '';
const commentBody = (line, at) => line.slice(at).replace(/^(#+|\/\/+)\s?/, '').trim();

// Every marker of a file: its line, the line it sanctions (its own when it trails code; else the first
// line below its comment block, unless that is blank or the end of the file), its head (the text on the
// marker's own line), its whole text, and the lines that text occupies.
function markersIn(lines, layout) {
  const out = [];
  lines.forEach((line, i) => {
    const at = layout[i].lineCommentAt;
    if (at < 0) return;
    const m = MARKER_RE.exec(line.slice(at));
    if (!m) return;
    const head = m[1].trim();
    const parts = [head];
    const textLines = [i];
    let target = i;
    if (isCommentLine(lines, layout, i)) {
      let k = i + 1;
      while (isCommentLine(lines, layout, k)) { parts.push(commentBody(lines[k], layout[k].lineCommentAt)); textLines.push(k); k++; }
      target = k < lines.length && lines[k].trim() !== '' ? k : -1;
    }
    out.push({ line: i + 1, target: target >= 0 ? target + 1 : undefined, head, text: parts.join(' ').trim(), textLines });
  });
  return out;
}

// One file, analysed: { lines, layout, lists: [{ line, col, items }], markers }.
function analyse(text, lang, where) {
  const lines = text.split('\n');
  const layout = commentLayout(lines, lang, where);
  const lists = [];
  let line = 0, lineStart = 0;
  for (let i = 0; i < text.length; i++) {
    if (text[i] === '\n') { line++; lineStart = i + 1; continue; }
    if (text[i] !== '[') continue;
    const col = i - lineStart;
    if (layout[line].ranges.some(([a, b]) => col >= a && col < b)) continue;
    const items = readStringList(text, i + 1, lang);
    if (items) lists.push({ line: line + 1, col, items });
  }
  return { lines, layout, lists, markers: markersIn(lines, layout) };
}

// The guard tokens (c) a set of analysed files offers: every UPPER_SNAKE token EMITTED — inside a string literal in
// code (a comment never runs, and a constant's name is not a failure anyone sees) — outside a sanction's text.
function guardTokensOf(files) {
  const tokens = new Set();
  for (const f of files) {
    const sanctionText = new Set();
    for (const mk of f.markers) for (const k of mk.textLines) sanctionText.add(k);
    f.lines.forEach((l, k) => {
      const comment = f.layout[k].ranges;
      for (const [a, b] of f.layout[k].strings) {
        if (comment.some(([ca, cb]) => a >= ca && a < cb)) continue;
        if (sanctionText.has(k) && f.layout[k].lineCommentAt >= 0 && a >= f.layout[k].lineCommentAt) continue;
        for (const t of l.slice(a, b).match(GUARD_TOKEN_RE) || []) tokens.add(t);
      }
    });
  }
  return tokens;
}

// The guards a sanction's text names, in each of the two universes: { runs, exists }, runs ⊆ exists.
function resolveGuard(text, guards) {
  const find = (u) => {
    const via = [];
    for (const t of text.match(GATE_FILE_RE) || []) if (u.gateFiles.has(path.basename(t))) via.push(path.basename(t));
    for (const t of text.match(SYSTEM_TEST_RE) || []) if (u.testDirs.has(t)) via.push(t);
    for (const t of text.match(GUARD_TOKEN_RE) || []) if (u.tokens.has(t)) via.push(t);
    return [...new Set(via)];
  };
  return { runs: find(guards.runs), exists: find(guards.exists) };
}

function classify(items, universe) {
  let nC = 0, nM = 0;
  for (const s of items) {
    if (universe.classes.has(s)) nC++;
    else if (universe.members.has(s)) nM++;
  }
  const names = nC + nM;
  const isName = names >= 2 && names * 2 >= items.length;
  const kind = !isName ? 'other' : nM === 0 ? 'CLASSES' : nC === 0 ? 'MEMBERS' : 'MIXED';
  return { nC, nM, nO: items.length - names, isName, kind };
}

function declarationKeyOf(file, list) {
  if (file.ext !== '.coffee') return undefined;
  const m = /^  (@?[A-Za-z_$][\w$]*)\s*:\s*$/.exec(file.lines[list.line - 1].slice(0, list.col));
  return m && DECLARATION_KEYS.has(m[1]) ? m[1] : undefined;
}

// files: analysed [{ rel, repo, ext, lines, layout, lists, markers }]. guards: { exists, runs } (each
// { gateFiles, testDirs, tokens }), complete (false when the tests repo is absent, so the name universe lacks
// the harness classes and the guard universe lacks the rigs) and runsKnown (false when the umbrella's fg is
// absent, so the commit-point legs cannot be read and "never runs" cannot be decided). Returns every list
// with its classification and state, every resolved sanction, and every marker problem (`note: true` =
// reported, not failed).
function evaluate(files, universe, guards) {
  const lists = [], problems = [], sanctions = [];
  for (const f of files) {
    const targeted = new Set(f.markers.filter(mk => mk.target).map(mk => mk.target));
    const listsOnLine = new Map();
    for (const l of f.lists) {
      const rec = { file: f, ...l, ...classify(l.items, universe), state: '-' };
      if (rec.isName) {
        rec.declKey = declarationKeyOf(f, l);
        if (rec.declKey) rec.state = 'DECLARATION';
        else rec.state = targeted.has(l.line) ? 'SANCTIONED' : 'UNSANCTIONED';
      }
      lists.push(rec);
      if (!listsOnLine.has(l.line)) listsOnLine.set(l.line, []);
      listsOnLine.get(l.line).push(rec);
    }
    // what cannot be decided on this checkout: the harness classes that make a list a name list, or the
    // guard a sanction names, may both live in the absent tests repo
    const undecidable = !guards.complete && f.repo !== 'tests';
    for (const mk of f.markers) {
      const at = { file: f, line: mk.line, text: mk.text };
      if (!mk.head) { problems.push({ token: 'SANCTION_EMPTY', ...at }); continue; }
      const onTarget = (mk.target && listsOnLine.get(mk.target)) || [];
      if (!onTarget.some(r => r.state === 'SANCTIONED')) {
        const maybeLive = undecidable && onTarget.some(r => r.state === '-');
        problems.push(maybeLive ? { token: 'SANCTION_UNVERIFIED', note: true, ...at } : { token: 'SANCTION_STALE', ...at });
        continue;
      }
      const { runs, exists } = resolveGuard(mk.text, guards);
      sanctions.push({ ...at, target: mk.target, via: runs, neverRun: exists.filter(g => !runs.includes(g)) });
      if (runs.length) continue;
      if (exists.length) {
        problems.push(guards.runsKnown && !undecidable
          ? { token: 'SANCTION_GUARD_NEVER_RUNS', names: exists, ...at }
          : { token: 'SANCTION_UNVERIFIED', note: true, ...at });
        continue;
      }
      problems.push(undecidable ? { token: 'SANCTION_UNVERIFIED', note: true, ...at } : { token: 'SANCTION_NAMES_NO_GUARD', ...at });
    }
  }
  return { lists, problems, sanctions };
}

// ---- the real tree ------------------------------------------------------------------------------------

function harvestUniverse(coffeeFiles) {
  const classes = new Set(), members = new Set();
  for (const p of coffeeFiles) {
    classes.add(path.basename(p, '.coffee'));
    const text = fs.readFileSync(p, 'utf8');
    const lines = text.split('\n');
    const masked = coffeeMask(text, p);    // a line inside a heredoc declares nothing
    const mixinIndent = mixinMemberIndent(lines);
    const mixinKey = mixinIndent === undefined ? undefined : new RegExp(`^ {${mixinIndent}}([A-Za-z_$][\\w$]*)\\s*:(?!:)`);
    for (const [i, raw] of lines.entries()) {
      if (masked[i].continuesLiteral) continue;
      const m = /^  @?([A-Za-z_$][\w$]*)\s*:(?!:)/.exec(raw) || (mixinKey && mixinKey.exec(raw));
      if (m) members.add(m[1]);
    }
  }
  return { classes, members };
}

// the names a sanction may cite as a guard file: buildSystem's .js files, build_it_please.sh, and the tests repo's
// scripts' .js and .sh files when it is present — but this gate's own
function gateFileNames(testsPresent) {
  const names = new Set(['build_it_please.sh', ...toolingFiles(BUILD_SYSTEM, ['.js']).map(p => path.basename(p))]);
  if (testsPresent) for (const p of toolingFiles(SCRIPTS, ['.js', '.sh'])) names.add(path.basename(p));
  names.delete(path.basename(SELF));
  return names;
}

// the tests (lib/tests-repo-code.js testNames, which refuses a tests tree it cannot read as tests)
function testDirNames(testsPresent) {
  return new Set(testsPresent ? testNames(TEST_DIRS) : []);
}

function loadFile(abs, repo) {
  const ext = path.extname(abs);
  const lang = LANG_OF_EXT[ext];
  if (!lang) fail(`${abs}: no comment syntax known for '${ext}' (scans .coffee, .py, .js)`);
  return { abs, rel: path.relative(UMBRELLA, abs), repo, ext, ...analyse(fs.readFileSync(abs, 'utf8'), lang, abs) };
}

const preview = (items) => items.slice(0, 6).join(', ') + (items.length > 6 ? ', …' : '');
const clip = (text) => (text.length > 160 ? text.slice(0, 157) + '…' : text);
const where = (r) => `${r.file.rel}:${r.line}`;

function printProblems(problems) {
  const say = {
    SANCTION_NAMES_NO_GUARD: 'its text names no real guard — the basename of an existing gate/rig file, an existing SystemTest_<name>, or an UPPER_SNAKE token some scanned file uses outside a sanction',
    SANCTION_GUARD_NEVER_RUNS: 'every guard it names EXISTS, but nothing runs it — not the build, a discovered self-test, nor an fg presuite/gauntlet leg (lib/what-runs.js) — so it can never fail. Name a guard that runs, or make the guard run',
    SANCTION_EMPTY: 'the marker carries no text on its own line: say what fails if the list goes stale',
    SANCTION_STALE: 'it sanctions no name list — none opens on the line it reaches (its own when it trails code, else the first line below its comment block). The list moved, became a declaration or was derived away: move the marker, or delete it',
  };
  for (const p of problems.filter(q => !q.note)) {
    console.error(rules.fired(p.token, `  ${p.token}  ${where(p)}  "${clip(p.text)}"`));
    console.error(`      ${say[p.token]}${p.names ? ` (named, never run: ${p.names.join(', ')})` : ''}`);
  }
}

function main(argv) {
  // Run from the Fizzygum/ repo root (build_it_please.sh does): node ./buildSystem/check-hand-lists.js [--src=DIR]
  // [--tests-repo=DIR] [--census] [--files <paths…>] [--fg=<path>] — the rails read another src tree for the Fizzygum
  // half, another tests repo for the tests half (a copy carrying a plant), and both for the name universe. That every
  // rule BITES, in both modes, is proven on every build by check-hand-lists-selftest.js.
  rejectUnknownArgs(argv, ['--census', '--names-only', '--min=', '--files', '--fg=', ...SOURCE_RAILS], 'check-hand-lists');
  ROOTS = sourceRoots(argv.filter((a) => SOURCE_RAILS.some((r) => a.startsWith(r))), 'check-hand-lists');
  HARNESS = path.join(ROOTS.testsRepo, HARNESS_DIR);
  SCRIPTS = path.join(ROOTS.testsRepo, 'scripts');
  TEST_DIRS = path.join(ROOTS.testsRepo, 'tests');
  const census = argv.includes('--census');
  const filesFlag = argv.indexOf('--files');
  const given = filesFlag >= 0 ? argv.slice(filesFlag + 1).filter(a => !a.startsWith('--')) : undefined;
  if (given && !given.length) fail('--files names no file');
  const minArg = argv.find(a => a.startsWith('--min='));
  const min = minArg ? Number(minArg.slice('--min='.length)) : 2;
  if (!Number.isInteger(min) || min < 1) fail(`--min wants a positive integer, got '${minArg}'`);

  const testsPresent = fs.existsSync(SCRIPTS) && fs.existsSync(HARNESS);
  const halves = [];
  try {
    halves.push({ repo: 'fizzygum', label: 'Fizzygum', baseline: BASELINE_FIZZYGUM, paths: [
      ...srcFiles(ROOTS.src), ...toolingFiles(BUILD_SYSTEM, ['.js', '.py']).filter(p => path.resolve(p) !== SELF_TEST_CORPUS)] });
    if (testsPresent) {
      halves.push({ repo: 'tests', label: 'Fizzygum-tests', baseline: BASELINE_TESTS, paths: [
        ...toolingFiles(SCRIPTS, ['.js']), ...harnessFiles(ROOTS.testsRepo)] });
    }
  } catch (e) { fail(e.message); }   // a tree the definitions refuse (SOURCE_/TOOLING_TREE_MALFORMED): nothing measured
  for (const h of halves) if (!h.paths.length) fail(`the ${h.label} half holds no file to scan — a gate that reads nothing certifies everything`);

  const universe = harvestUniverse(compiledFiles(ROOTS));
  if (!universe.classes.size || !universe.members.size) {
    fail(`the name universe is empty (${universe.classes.size} class(es), ${universe.members.size} member(s)) — an empty universe classifies nothing as a name and certifies every list`);
  }

  const treeFiles = halves.flatMap(h => h.paths.map(p => loadFile(p, h.repo)));
  const givenFiles = (given || []).map(g => {
    const abs = path.resolve(process.cwd(), g);
    if (!fs.existsSync(abs) || !fs.statSync(abs).isFile()) fail(`--files: no such file ${g}`);
    return treeFiles.find(f => f.abs === abs) || loadFile(abs, 'given');
  });
  const universeFiles = [...treeFiles, ...givenFiles.filter(f => !treeFiles.includes(f))];
  // WHAT RUNS (lib/what-runs.js): the scripts the build, the discovered self-tests and fg's legs launch. The
  // world's own sources (src, the harness) run when the suite runner does: a token one of them emits is failed
  // on by every suite leg (scripts/lib/gate-tokens.js), and every SystemTest_ directory is a test that leg plays.
  const fgArg = argv.find(a => a.startsWith('--fg='));
  let ran;
  // the tests repo's scripts are the --tests-repo= rail's, the ones this gate reads
  try { ran = runSet({ ...WHAT_RUNS_LAYOUT, tests: ROOTS.testsRepo, ...(fgArg ? { fg: path.resolve(fgArg.slice('--fg='.length)) } : {}) }); }
  catch (e) { fail(e.message); }
  const runBasenames = new Set([...ran.files].map(f => path.basename(f)));
  const worldRuns = runBasenames.has('run-all-headless.js');
  // this gate's own tokens never vouch for a sanction: it checks that a list is examined, never that it is current
  const tokenFiles = universeFiles.filter(f => f.abs !== SELF);
  const exists = { gateFiles: gateFileNames(testsPresent), testDirs: testDirNames(testsPresent), tokens: guardTokensOf(tokenFiles) };
  const runs = { gateFiles: new Set([...exists.gateFiles].filter(n => runBasenames.has(n))),
                 testDirs: worldRuns ? exists.testDirs : new Set(),
                 // a world source is a .coffee file the WORLD compiles — src or the harness — never a --files plant, which
                 // would otherwise vouch for its own sanction through any token it prints
                 tokens: guardTokensOf(tokenFiles.filter(f => ran.files.has(f.abs) || (worldRuns && f.ext === '.coffee' && f.repo !== 'given'))) };
  const guards = { exists, runs, complete: testsPresent, runsKnown: ran.fgPresent };
  const checked = given ? givenFiles : treeFiles;
  const { lists, problems, sanctions } = evaluate(checked, universe, guards);

  if (census) return printCensus(lists, sanctions, problems, { min, namesOnly: argv.includes('--names-only'), testsPresent });

  const failures = problems.filter(p => !p.note);
  const notes = problems.filter(p => p.note);
  const nameLists = lists.filter(l => l.isName);
  const countOf = (ls, state) => ls.filter(l => l.state === state).length;
  let over = false;

  if (given) {
    const unsanctioned = nameLists.filter(l => l.state === 'UNSANCTIONED');
    const counts = `${nameLists.length} name list(s) — ${countOf(nameLists, 'DECLARATION')} declaration, ` +
      `${countOf(nameLists, 'SANCTIONED')} sanctioned, ${unsanctioned.length} unsanctioned`;
    for (const s of sanctions.filter(x => x.via.length)) console.log(`  sanction ${where(s)} -> line ${s.target}, guard that runs: ${s.via.join(', ')}`);
    if (unsanctioned.length) {
      over = true;
      console.error(`\n[hand-lists] FAIL — ${unsanctioned.length} unsanctioned name list(s) (with --files every one is a violation):`);
      for (const l of unsanctioned) console.error(rules.fired('UNSANCTIONED_NAME_LIST', `  UNSANCTIONED_NAME_LIST  ${where(l)}  [${preview(l.items)}]`));
    }
    console.log(`[hand-lists] ${over || failures.length ? '' : 'OK — '}${checked.length} given file(s): ${counts}.`);
  } else {
    const summary = [];
    for (const h of halves) {
      const own = nameLists.filter(l => l.file.repo === h.repo);
      const unsanctioned = own.filter(l => l.state === 'UNSANCTIONED');
      summary.push(`${h.label}: ${own.length} name list(s) = ${countOf(own, 'DECLARATION')} declaration + ` +
        `${countOf(own, 'SANCTIONED')} sanctioned + ${unsanctioned.length} unsanctioned (baseline ${h.baseline})`);
      if (unsanctioned.length > h.baseline) {
        over = true;
        console.error(`\n[hand-lists] FAIL — ${h.label} holds ${unsanctioned.length} unsanctioned name list(s), over its baseline of ${h.baseline}. Every one:`);
        for (const l of unsanctioned) console.error(rules.fired('OVER_BASELINE', `  ${where(l)}  [${preview(l.items)}]`));
      } else if (unsanctioned.length < h.baseline && testsPresent) {
        // (without the harness classes some lists read as data, so a lower count there is no gain to bank)
        console.log(`[hand-lists] NOTE — ${h.label} is at ${unsanctioned.length} unsanctioned name list(s), below its baseline of ${h.baseline}: tighten BASELINE_${h.repo.toUpperCase()} in buildSystem/check-hand-lists.js to lock the gain in.`);
      }
    }
    if (over) {
      console.error('\nFIX: derive the list from where its names are declared, or assert it both ways and sanction it');
      console.error('naming the guard that fails:  # hand-list-sanctioned: <the gate, rig, SystemTest or token that fails when it goes stale>');
      console.error('on the line holding its `[` or directly above it (`//` in .js).');
    }
    if (!testsPresent) console.log('[hand-lists] tests half SKIPPED — sibling Fizzygum-tests not present (its scripts and harness are not checked, and the Fizzygum half is classified without the harness classes).');
    if (!over && !failures.length) {
      console.log(`[hand-lists] OK — ${treeFiles.length} file(s), universe ${universe.classes.size} class(es) + ${universe.members.size} member name(s); ${summary.join('; ')}.`);
    } else {
      console.log(`[hand-lists] ${summary.join('; ')}.`);
    }
  }

  if (notes.length) {
    const absent = [!testsPresent && 'the Fizzygum-tests repo', !ran.fgPresent && "the umbrella's fg (whose legs say what runs at a commit point)"].filter(Boolean).join(' and ');
    console.log(`[hand-lists] NOTE — ${notes.length} sanction(s) UNVERIFIED: the guard each names, or the classes that make its list a name list, cannot be judged without ${absent}:`);
    for (const n of notes) console.log(`  ${where(n)}  "${clip(n.text)}"`);
  }
  if (failures.length) {
    console.error(`\n[hand-lists] FAIL — ${failures.length} sanction marker(s) are wrong (never ratcheted):`);
    printProblems(failures);
  }
  return over || failures.length ? 1 : 0;
}

function printCensus(lists, sanctions, problems, { min, namesOnly, testsPresent }) {
  const order = { CLASSES: 0, MEMBERS: 1, MIXED: 2, other: 3 };
  const shown = lists.filter(l => l.items.length >= min && (!namesOnly || l.isName))
    .sort((a, b) => order[a.kind] - order[b.kind] || a.file.rel.localeCompare(b.file.rel) || a.line - b.line);
  console.log('KIND       n   C   M   o  STATE         file:line  [items]');
  for (const l of shown) {
    console.log(`${l.kind.padEnd(7)} ${String(l.items.length).padStart(4)}${String(l.nC).padStart(4)}${String(l.nM).padStart(4)}${String(l.nO).padStart(4)}  ` +
      `${l.state.padEnd(12)}  ${where(l)}  [${preview(l.items)}]${l.state === 'DECLARATION' ? `  (${l.declKey})` : ''}`);
  }
  if (sanctions.length || problems.length) {
    console.log('\nSANCTIONS');
    for (const s of sanctions) {
      console.log(`  ${where(s)} -> line ${s.target}  guard: ${s.via.length ? s.via.join(', ') : 'NONE THAT RUNS'}` +
        `${s.neverRun.length ? `  (named, never run: ${s.neverRun.join(', ')})` : ''}  "${clip(s.text)}"`);
    }
    for (const p of problems) if (!['SANCTION_NAMES_NO_GUARD', 'SANCTION_GUARD_NEVER_RUNS', 'SANCTION_UNVERIFIED'].includes(p.token)) console.log(`  ${where(p)}  ${p.token}  "${clip(p.text)}"`);
  }
  const all = lists.filter(l => l.items.length >= min);
  const kinds = Object.keys(order).map(k => `${all.filter(l => l.kind === k).length} ${k}`).join(', ');
  const perRepo = ['fizzygum', 'tests', 'given'].map(repo => {
    const own = all.filter(l => l.isName && l.file.repo === repo);
    if (!own.length) return undefined;
    const n = (s) => own.filter(l => l.state === s).length;
    return `${repo}: ${n('DECLARATION')} declaration / ${n('SANCTIONED')} sanctioned / ${n('UNSANCTIONED')} unsanctioned`;
  }).filter(Boolean);
  console.log(`\n${all.length} string list(s) with ${min}+ items (${kinds}); name lists — ${perRepo.join('; ') || 'none'}` +
    (testsPresent ? '' : ' (tests half SKIPPED: Fizzygum-tests absent)'));
  return 0;
}

module.exports = { analyse, classify, evaluate, resolveGuard, guardTokensOf, gateFileNames, harvestUniverse, preview, LANG_OF_EXT };

if (require.main === module) process.exit(main(process.argv.slice(2)));

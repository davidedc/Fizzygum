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
// Dot-directories (`.scratch`), node_modules and __pycache__ are skipped, and so is the tests repo's
// tests/ — macro sources are test CONTENT, held by that repo's own gates. THIS file is skipped as well:
// its --self-test corpus is made of exactly the lists it hunts, so scanning it would count the fixtures.
// Without the tests repo the tests half SKIPS and says so, as check-dead-methods.js and
// check-part-edges.js do.
//
// THE NAME UNIVERSE. CLASS names: the basename of every .coffee file under Fizzygum/src and the harness
// (one class per file, filename = class name; src/boot's files count too, and name boot sources).
// MEMBER names: every class-body key at the class-body indent (`  name:` / `  @name:`) in the same files,
// plus a mixin's member keys at the indent its onceAddedClassProperties hash locks
// (lib/coffee-method-header.js mixinMemberIndent: what a mixin puts on a widget is a member like any
// other). Lines inside a heredoc declare nothing — a code sample in a string is not a class body. This
// harvest is its own because no shared one answers this question: lib/name-definitions.js counts ANY
// key at ANY indent (an option object's keys too — the over-approximation its two consumers rely on,
// which here would turn data lists into "name lists"); lib/coffee-method-header.js sees METHODS only,
// while the lists that rotted named FIELDS (world collections, drag-embed slots); lib/install-edges.js
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
// HOW A SANCTION'S GUARD IS RESOLVED — mechanically, by at least one of:
//   (a) the basename of an existing gate or rig file: Fizzygum/buildSystem/*.js and lib/*.js,
//       Fizzygum/build_it_please.sh, and every .js or .sh under Fizzygum-tests/scripts (the gate runners
//       are shell scripts). This file does not count: it checks that a list is examined, never current;
//   (b) `SystemTest_<name>` with an existing Fizzygum-tests/tests/SystemTest_<name>/ directory;
//   (c) an UPPER_SNAKE token — two or more segments joined by `_` or `-`, each starting with a letter
//       (`MENU_CONTRIBUTOR_UNSWEPT`, `TIERNAMING-UNCLASSIFIED`) — that occurs in some scanned file
//       OUTSIDE every sanction's own text, so a sanction cannot vouch for itself.
//   A sanction's text is the rest of its marker's line plus the comment lines below it in the same block.
//   One resolving none fails as SANCTION_NAMES_NO_GUARD — always, never ratcheted. A marker with no text
//   on its own line fails as SANCTION_EMPTY; one that sanctions no name list fails as SANCTION_STALE (the
//   list moved, became a declaration, or was derived away, and a marker that sanctions nothing reads to
//   the next author as if it did). ⚠ Resolution proves the guard EXISTS, not that it covers the list: it
//   makes the author name what fails, which a reviewer can then check; it cannot check it for them.
//   Without the tests repo two things about a Fizzygum-half sanction cannot be decided — the guard it
//   names may live there, and so may the harness classes that make its list a name list — so a sanction
//   resolving no guard, or sitting above a list that reads as data, is listed UNVERIFIED in a NOTE rather
//   than failed. One above a line where no list opens at all is SANCTION_STALE on every checkout.
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
//       other), state, and each sanction's resolved guard — then exit 0: a census, never a gate
//   node buildSystem/check-hand-lists.js --files <path…>  only the given files; there EVERY unsanctioned
//       name list is a violation (no ratchet), so a plant fails exactly
//   node buildSystem/check-hand-lists.js --self-test      an in-memory corpus showing each direction bite

const fs = require('fs');
const path = require('path');
const { mixinMemberIndent } = require('./lib/coffee-method-header');

const FIZZYGUM = path.resolve(__dirname, '..');
const UMBRELLA = path.resolve(FIZZYGUM, '..');
const TESTS_REPO = path.join(UMBRELLA, 'Fizzygum-tests');
const SRC = path.join(FIZZYGUM, 'src');
const BUILD_SYSTEM = path.join(FIZZYGUM, 'buildSystem');
const HARNESS = path.join(TESTS_REPO, 'Automator-and-test-harness-src');
const SCRIPTS = path.join(TESTS_REPO, 'scripts');
const TEST_DIRS = path.join(TESTS_REPO, 'tests');
const SELF = path.resolve(__filename);

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
const LANG_OF_EXT = { '.coffee': 'hash', '.py': 'hash', '.js': 'slash' };

function fail(msg) { console.error(`[hand-lists] ERROR — ${msg}`); process.exit(2); }

function walk(dir, exts, acc = []) {
  if (!fs.existsSync(dir)) return acc;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    if (e.name.startsWith('.') || e.name === 'node_modules' || e.name === '__pycache__') continue;
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, exts, acc);
    else if (exts.some(x => e.name.endsWith(x))) acc.push(p);
  }
  return acc;
}

// ---- the per-file engine (pure: text in, records out — what --self-test drives) ----------------------

// For each line, the column ranges that are COMMENT and the column where a LINE comment opens (-1 if
// none), from a string-aware scan that restarts on every line; .js block comments carry across lines.
function commentLayout(lines, lang) {
  const out = [];
  let inBlock = false;
  for (const line of lines) {
    const ranges = [];
    let lineCommentAt = -1, quote = null, blockFrom = inBlock ? 0 : -1;
    for (let i = 0; i < line.length; i++) {
      const c = line[i];
      if (blockFrom >= 0) {
        if (c === '*' && line[i + 1] === '/') { ranges.push([blockFrom, i + 2]); blockFrom = -1; i++; }
        continue;
      }
      if (quote) {
        if (c === '\\') i++;
        else if (c === quote) quote = null;
        continue;
      }
      if (c === '"' || c === "'" || c === '`') { quote = c; continue; }
      if (lang === 'hash' && c === '#') { lineCommentAt = i; break; }
      if (lang === 'slash' && c === '/' && line[i + 1] === '/') { lineCommentAt = i; break; }
      if (lang === 'slash' && c === '/' && line[i + 1] === '*') { blockFrom = i; i++; }
    }
    inBlock = blockFrom >= 0;
    if (inBlock) ranges.push([blockFrom, line.length]);
    if (lineCommentAt >= 0) ranges.push([lineCommentAt, line.length]);
    out.push({ ranges, lineCommentAt });
  }
  return out;
}

// From just after a `[`, the items of a pure string list, or null when anything other than string
// literals, separators and comments comes before its `]` (or the list is empty).
function readStringList(text, j, lang) {
  const items = [];
  for (;;) {
    while (j < text.length && /[\s,]/.test(text[j])) j++;
    if (j >= text.length) return null;
    if ((lang === 'hash' && text[j] === '#') || (lang === 'slash' && text.startsWith('//', j))) {
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
function analyse(text, lang) {
  const lines = text.split('\n');
  const layout = commentLayout(lines, lang);
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

// The guard tokens (c) a set of analysed files offers: every UPPER_SNAKE token outside a sanction's text.
function guardTokensOf(files) {
  const tokens = new Set();
  for (const f of files) {
    const masked = new Map();   // line index -> the part of it that is not sanction text
    for (const mk of f.markers) {
      for (const k of mk.textLines) masked.set(k, k === mk.line - 1 ? f.lines[k].slice(0, f.layout[k].lineCommentAt) : '');
    }
    f.lines.forEach((l, k) => {
      for (const t of (masked.has(k) ? masked.get(k) : l).match(GUARD_TOKEN_RE) || []) tokens.add(t);
    });
  }
  return tokens;
}

function resolveGuard(text, guards) {
  const via = [];
  for (const t of text.match(GATE_FILE_RE) || []) if (guards.gateFiles.has(path.basename(t))) via.push(path.basename(t));
  for (const t of text.match(SYSTEM_TEST_RE) || []) if (guards.testDirs.has(t)) via.push(t);
  for (const t of text.match(GUARD_TOKEN_RE) || []) if (guards.tokens.has(t)) via.push(t);
  return [...new Set(via)];
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

// files: analysed [{ rel, repo, ext, lines, layout, lists, markers }]; guards.complete is false when the
// tests repo is absent, so the name universe lacks the harness classes and the guard universe lacks the
// rigs. Returns every list with its classification and state, every resolved sanction, and every marker
// problem (`note: true` = reported, not failed).
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
      const via = resolveGuard(mk.text, guards);
      sanctions.push({ ...at, target: mk.target, via });
      if (via.length) continue;
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
    const lines = fs.readFileSync(p, 'utf8').split('\n');
    const mixinIndent = mixinMemberIndent(lines);
    const mixinKey = mixinIndent === undefined ? undefined : new RegExp(`^ {${mixinIndent}}([A-Za-z_$][\\w$]*)\\s*:(?!:)`);
    let inHeredoc = false;
    for (const raw of lines) {
      const wasInHeredoc = inHeredoc;
      if ((raw.match(/"""|'''/g) || []).length % 2) inHeredoc = !inHeredoc;
      if (wasInHeredoc) continue;
      const m = /^  @?([A-Za-z_$][\w$]*)\s*:(?!:)/.exec(raw) || (mixinKey && mixinKey.exec(raw));
      if (m) members.add(m[1]);
    }
  }
  return { classes, members };
}

function gateFileNames(testsPresent) {
  const names = new Set(['build_it_please.sh']);
  for (const dir of [BUILD_SYSTEM, path.join(BUILD_SYSTEM, 'lib')]) {
    if (!fs.existsSync(dir)) continue;
    for (const n of fs.readdirSync(dir)) if (n.endsWith('.js')) names.add(n);
  }
  if (testsPresent) for (const p of walk(SCRIPTS, ['.js', '.sh'])) names.add(path.basename(p));
  names.delete(path.basename(SELF));
  return names;
}

function testDirNames(testsPresent) {
  if (!testsPresent || !fs.existsSync(TEST_DIRS)) return new Set();
  return new Set(fs.readdirSync(TEST_DIRS, { withFileTypes: true })
    .filter(e => e.isDirectory() && e.name.startsWith('SystemTest_')).map(e => e.name));
}

function loadFile(abs, repo) {
  const ext = path.extname(abs);
  const lang = LANG_OF_EXT[ext];
  if (!lang) fail(`${abs}: no comment syntax known for '${ext}' (scans .coffee, .py, .js)`);
  return { abs, rel: path.relative(UMBRELLA, abs), repo, ext, ...analyse(fs.readFileSync(abs, 'utf8'), lang) };
}

const preview = (items) => items.slice(0, 6).join(', ') + (items.length > 6 ? ', …' : '');
const clip = (text) => (text.length > 160 ? text.slice(0, 157) + '…' : text);
const where = (r) => `${r.file.rel}:${r.line}`;

function printProblems(problems) {
  const say = {
    SANCTION_NAMES_NO_GUARD: 'its text names no real guard — the basename of an existing gate/rig file, an existing SystemTest_<name>, or an UPPER_SNAKE token some scanned file uses outside a sanction',
    SANCTION_EMPTY: 'the marker carries no text on its own line: say what fails if the list goes stale',
    SANCTION_STALE: 'it sanctions no name list — none opens on the line it reaches (its own when it trails code, else the first line below its comment block). The list moved, became a declaration or was derived away: move the marker, or delete it',
  };
  for (const p of problems.filter(q => !q.note)) {
    console.error(`  ${p.token}  ${where(p)}  "${clip(p.text)}"`);
    console.error(`      ${say[p.token]}`);
  }
}

function main(argv) {
  if (argv.includes('--self-test')) return selfTest();

  const census = argv.includes('--census');
  const filesFlag = argv.indexOf('--files');
  const given = filesFlag >= 0 ? argv.slice(filesFlag + 1).filter(a => !a.startsWith('--')) : undefined;
  if (given && !given.length) fail('--files names no file');
  const minArg = argv.find(a => a.startsWith('--min='));
  const min = minArg ? Number(minArg.slice('--min='.length)) : 2;
  if (!Number.isInteger(min) || min < 1) fail(`--min wants a positive integer, got '${minArg}'`);

  const testsPresent = fs.existsSync(SCRIPTS) && fs.existsSync(HARNESS);
  const halves = [{ repo: 'fizzygum', label: 'Fizzygum', baseline: BASELINE_FIZZYGUM, paths: [
    ...walk(SRC, ['.coffee']), ...walk(BUILD_SYSTEM, ['.js', '.py']).filter(p => path.resolve(p) !== SELF)] }];
  if (testsPresent) {
    halves.push({ repo: 'tests', label: 'Fizzygum-tests', baseline: BASELINE_TESTS, paths: [
      ...walk(SCRIPTS, ['.js']), ...walk(HARNESS, ['.coffee'])] });
  }
  for (const h of halves) if (!h.paths.length) fail(`the ${h.label} half holds no file to scan — a gate that reads nothing certifies everything`);

  const universe = harvestUniverse([...walk(SRC, ['.coffee']), ...(testsPresent ? walk(HARNESS, ['.coffee']) : [])]);
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
  const guards = { gateFiles: gateFileNames(testsPresent), testDirs: testDirNames(testsPresent),
                   tokens: guardTokensOf(universeFiles), complete: testsPresent };
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
    for (const s of sanctions.filter(x => x.via.length)) console.log(`  sanction ${where(s)} -> line ${s.target}, guard: ${s.via.join(', ')}`);
    if (unsanctioned.length) {
      over = true;
      console.error(`\n[hand-lists] FAIL — ${unsanctioned.length} unsanctioned name list(s) (with --files every one is a violation):`);
      for (const l of unsanctioned) console.error(`  UNSANCTIONED_NAME_LIST  ${where(l)}  [${preview(l.items)}]`);
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
        for (const l of unsanctioned) console.error(`  ${where(l)}  [${preview(l.items)}]`);
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
    console.log(`[hand-lists] NOTE — ${notes.length} sanction(s) UNVERIFIED: the guard each names, or the classes that make its list a name list, may live in the absent Fizzygum-tests repo:`);
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
    for (const s of sanctions) console.log(`  ${where(s)} -> line ${s.target}  guard: ${s.via.length ? s.via.join(', ') : 'NONE'}  "${clip(s.text)}"`);
    for (const p of problems) if (p.token !== 'SANCTION_NAMES_NO_GUARD' && p.token !== 'SANCTION_UNVERIFIED') console.log(`  ${where(p)}  ${p.token}  "${clip(p.text)}"`);
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

// ---- --self-test: an in-memory corpus, each direction both ways --------------------------------------
// The corpus is made of exactly what the gate hunts, which is why this file is never scanned. Every list
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
];

// [file, a substring unique to the list's opening line, expected state, expected kind]
const EXPECTED_LISTS = [
  ['corpus/unsanctioned-classes.coffee', '@things:', 'UNSANCTIONED', 'CLASSES'],         // multi-line, interleaved comments
  ['corpus/unsanctioned-classes.coffee', '@interpolated:', 'UNSANCTIONED', 'CLASSES'],   // a `#` inside a string opens no comment
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
];

function selfTest() {
  const universe = { classes: new Set(['Widget', 'PanelWdgt', 'FrameWdgt', 'MenuWdgt']),
                     members: new Set(['fooField', 'barMethod', 'bazKey', 'quxVerb']) };
  const files = CORPUS.map(c => {
    const ext = path.extname(c.rel);
    return { rel: c.rel, repo: 'fizzygum', ext, ...analyse(c.text.join('\n'), LANG_OF_EXT[ext]) };
  });
  const gateFiles = gateFileNames(false);
  if (!gateFiles.has('check-dead-methods.js')) fail('self-test: the real tree has no buildSystem/check-dead-methods.js to resolve guard (a) against');
  const guards = { gateFiles, testDirs: new Set(['SystemTest_corpusFixture']), tokens: guardTokensOf(files), complete: true };
  const { lists, problems } = evaluate(files, universe, guards);
  let ok = true;
  const check = (pass, msg) => { console[pass ? 'log' : 'error'](`  ${pass ? 'ok  ' : 'FAIL'} ${msg}`); if (!pass) ok = false; };
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
  console.log(ok ? '[hand-lists] self-test PASS' : '[hand-lists] self-test FAIL');
  return ok ? 0 : 1;
}

module.exports = { analyse, classify, evaluate, resolveGuard };

if (require.main === module) process.exit(main(process.argv.slice(2)));

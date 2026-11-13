'use strict';
// what-runs.js — the one statement of WHAT RUNS: which scripts the build and the commit-point legs actually execute,
// and which files the discovering runners pick up by name. A check that nothing runs proves nothing (a self-test
// rots, a stale-name check goes stale silently, a sanction names a guard that never fires), so the two places where
// reliance on a check is written down read this:
//   - buildSystem/run-selftests.js discovers the self-tests it runs here (CONVENTIONS), and
//   - check-hand-lists.js accepts a sanction's guard only when runSet() contains it.
// Plan, measurements and the review it survived: docs/archive/unrun-checks-plan.md.
//
// THE ROOTS. Fizzygum/build_it_please.sh (every build), with its gate table, buildSystem/gates.js (each row a launch of
// its script by the command line run-gates.js gives it); Fizzygum/build_and_smoke.sh when present (the build's own
// pre-commit check: the boot smoke it launches is a gate like any other); and, when the umbrella's local `fg` wrapper is
// present, the bodies of its fg_build / fg_suite / run_lint / run_leg functions (the presuite and gauntlet legs; all four
// must be found, or the reading is an ERROR). `fg` is in no repo, so a bare clone has the two versioned roots alone and runSet() says
// so (`fgPresent: false`); its readers then treat a commit-point-only fact as undecidable, never as false.
//
// AN EDGE IS AN INVOCATION, NOT A MENTION. A file runs another when it LAUNCHES it:
//   - shell (.sh, and fg's function bodies), read by a small lexer (shellCommands, below): a script that is the PROGRAM
//     a command executes, or that follows an INTERPRETER word (node, bash, sh, python3, source, `.`) — a flag's value
//     included (`node runner.js --prelude=x.js`: the runner injects it into its pages). A printing command, a test, a
//     file operation, an assignment, a heredoc body and a comment launch nothing; a `$( … )` substitution is a command
//     of its own;
//   - JavaScript: a `require('<relative path>')` (the module's code runs), or a script named among the string
//     arguments of a `path.join(…)` / `path.resolve(…)` call — how every launch site locates what it spawns or
//     injects, cwd-independently. A help or error message names a tool and never builds its path;
//   - Python: nothing. A .py file is a leaf (its docstrings name shell scripts; none launches one).
// A SELF-TEST runs, but its own edges are not followed: what it loads it exercises on FIXTURES, so a command-line tool
// that only its self-test requires does not run its check.
// A path in an edge names its file by its tail (`$FT/scripts/x.sh` and `../Fizzygum-tests/scripts/x.js` both end in a
// scanned file's path); a bare basename resolves to every scanned file of that name.
//
// DISCOVERY. A runner that finds its inputs by NAME runs every file its convention matches. CONVENTIONS is that table,
// and the runners call discover() so the table and the runners cannot disagree. A convention keyed to an invoking
// COMMAND (`--headless` or not) applies only to a shell invocation of its runner whose command matches.
//
// BLIND SPOTS, plainly. A launch spelled any other way — a path assembled with `+`, a template literal, a variable
// holding a path computed elsewhere, a path handed to a shell FUNCTION (`run_audited_suite x-prelude.js`) — is not
// seen, so its target reads as never run: the safe direction, since the reader then asks for a guard that is seen to
// run. A required module counts as run because its code runs, even where its own command-line half (behind
// `require.main === module`) does not. A root's own conditions (`if $PROFILE_SHIPS_TESTS`) are not evaluated: a gate
// behind a profile condition counts as run — and so is a gate-table row's WHEN, with one exception the runner makes
// too: a row whose script lives in the tests repo, in a layout with no tests repo, runs nothing. A row's arguments are
// not read for scripts (a shell line's are). A leg of `fg` is trusted to be in a wave; `fg` is read, never executed.

const fs = require('fs');
const path = require('path');
const { maskJs } = require('./js-mask');

const FIZZYGUM = path.resolve(__dirname, '..', '..');
const DEFAULT_LAYOUT = {
  fizzygum: FIZZYGUM,
  tests: path.join(path.dirname(FIZZYGUM), 'Fizzygum-tests'),
  fg: path.join(path.dirname(FIZZYGUM), 'fg'),
};
const FG_FUNCTIONS = ['fg_build', 'fg_suite', 'run_lint', 'run_leg'];
// the build's gate runner, and the table of gates it runs: read here (its rows are data) when the build launches the
// runner — a table nobody runs gates nothing
const GATE_RUNNER = 'buildSystem/run-gates.js';
const GATE_TABLE = 'buildSystem/gates.js';

// The discovering runners and what each picks up. `onLine`, when present, says which shell invocations of the runner
// run this kind.
const CONVENTIONS = {
  selftest:         { re: /-selftest\.js$/,          runner: 'run-selftests.js', onLine: (l) => !/--headless\b/.test(l) },
  selftestHeadless: { re: /-selftest-headless\.js$/, runner: 'run-selftests.js', onLine: (l) => /--headless\b/.test(l) },
  prelude:          { re: /-prelude\.js$/,           runner: 'preludes-install-selftest-headless.js' },
};

// THE TOOLING'S OWN FILES — the one definition every reader of them shares (the run set and discovery here, the hand-list
// scan, the Node rigs' code set, the tooling's self-tests, the similar- and duplicate-code scans): Fizzygum's buildSystem/
// and scripts/ (recursively) and its top-level shell scripts, and the tests repo's scripts/ when present; `.js`, `.sh` and
// `.py` files. Never the tooling: a dot entry (a gitignored scratch such as scripts/.scratch, a dot file), a node_modules
// (a dependency tree), a __pycache__ (bytecode) — skippedEntry() says so for any walk of the repos. A SYMLINK is refused
// (TOOLING_TREE_MALFORMED, naming it), as lib/source-files.js refuses one in the sources: a walk that follows it reads a
// file twice or outside the tree, one that does not reads it never, and the readers would disagree. Sorted, absolute.
const skippedEntry = (name) => name.startsWith('.') || name === 'node_modules' || name === '__pycache__';
function scriptFiles(layout = DEFAULT_LAYOUT) {
  const out = [];
  // `deep`: a root walked whole for .js/.sh/.py; else Fizzygum's own top level, for its .sh files alone
  const visit = (dir, deep) => {
    if (!fs.existsSync(dir)) return;
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      if (skippedEntry(e.name)) continue;
      const p = path.join(dir, e.name);
      const wanted = deep ? /\.(js|sh|py)$/.test(e.name) : /\.sh$/.test(e.name);
      if (e.isSymbolicLink()) {
        if (deep || wanted) throw new Error('TOOLING_TREE_MALFORMED ' + p + ': a symlink — the tooling\'s files are read where they are');
        continue;
      }
      if (e.isDirectory()) { if (deep) visit(p, true); }
      else if (e.isFile() && wanted) out.push(p);
    }
  };
  visit(path.join(layout.fizzygum, 'buildSystem'), true);
  visit(path.join(layout.fizzygum, 'scripts'), true);
  visit(layout.fizzygum, false);
  visit(path.join(layout.tests, 'scripts'), true);
  return out.sort();
}

function discover(kind, layout = DEFAULT_LAYOUT) {
  const c = CONVENTIONS[kind];
  if (!c) throw new Error(`what-runs: no convention '${kind}'`);
  return scriptFiles(layout).filter((f) => c.re.test(path.basename(f)));
}

// The files a path token names: by its tail when it has a directory part, else by basename. Leading punctuation (a
// `${3:-` default's `-`), `$VAR/` / `${VAR}/`, `./`, `../` and a lone leading `/` (what `"$(dirname "$0")/x.js"` leaves) are
// dropped before the tail is matched.
function resolver(files) {
  const byBase = new Map();
  for (const f of files) {
    const b = path.basename(f);
    if (!byBase.has(b)) byBase.set(b, []);
    byBase.get(b).push(f);
  }
  return (token) => {
    const cands = byBase.get(path.basename(token)) || [];
    const tail = token.replace(/^[^\w$./]+/, '').replace(/^(?:\$\{?\w+\}?\/|\.{1,2}\/|\/)+/, '');
    if (!tail.includes('/')) return cands;
    return cands.filter((f) => f.endsWith('/' + tail));
  };
}

const SCRIPT_TOKEN = /[\w.\/\${}-]*?[\w.-]+\.(?:js|sh|py)\b/g;

// ---- shell: a small lexer, enough to tell a LAUNCH from a mention -------------------------------------------------
// A path runs when it is the PROGRAM a command executes (`./build_it_please.sh`), or when it follows an INTERPRETER
// word in the command (`node x.js`, `to 300 node x.js`, `xargs … bash x.sh`, `source x.sh`) — a flag value included
// (`node runner.js --prelude="${3:-x.js}"`). A printing command (echo, printf, fg's ban, `:`) runs nothing, whatever it
// names; so does a test (`[ -f x.js ]`), a file operation or an assignment, even one heading a command that runs an
// interpreter (`X=x.js node runner.js`): no runner takes a script through the environment — those rails are retired
// and REFUSED (Fizzygum-tests/scripts/lib/page-rails.js) — so a script named that way reads as not run, the safe
// direction. Each `$( … )` / backtick substitution is lexed as commands of its own (its place in the word is kept
// as `$S`, so a path built on it still reads as a path); a heredoc's body is data; comments are cut.
const INTERPRETERS = new Set(['node', 'bash', 'sh', 'zsh', 'python', 'python3', 'source', '.']);
const PRINTERS = new Set(['echo', 'printf', 'ban', ':']);
const KEYWORDS = new Set(['then', 'else', 'elif', 'do', 'if', 'while', 'until', '!', '{', '}', 'time', 'exec']);

// the index of the ) closing the ( at `open`, skipping quoted text
function matchParen(src, open) {
  let depth = 0;
  for (let i = open; i < src.length; i++) {
    const c = src[i];
    if (c === '\\') { i++; continue; }
    if (c === "'" || c === '"') { const e = src.indexOf(c, i + 1); if (e < 0) return -1; i = e; continue; }
    if (c === '(') depth++;
    else if (c === ')' && --depth === 0) return i;
  }
  return -1;
}

// Every simple command of a shell text, as its words: [[{ text, quoted, headQuoted }]].
function shellCommands(text) {
  const commands = [];
  const lex = (src) => {
    let words = [], word = null, i = 0;
    const heredocs = [];
    const endWord = () => { if (word) { words.push(word); word = null; } };
    const endCommand = () => { endWord(); if (words.length) commands.push(words); words = []; };
    const append = (piece, quoted) => {
      if (!word) word = { text: '', quoted: false, headQuoted: quoted };
      word.text += piece;
      if (quoted) word.quoted = true;
    };
    const substitute = (from, to) => { lex(src.slice(from, to)); };
    while (i < src.length) {
      const c = src[i];
      if (c === '$' && src[i + 1] === '(' && src[i + 2] !== '(') {
        const e = matchParen(src, i + 1);
        if (e < 0) { i = src.length; break; }
        substitute(i + 2, e); append('$S', false); i = e + 1; continue;
      }
      if (c === '\x60') {
        const e = src.indexOf('\x60', i + 1);
        if (e < 0) { i = src.length; break; }
        substitute(i + 1, e); append('$S', false); i = e + 1; continue;
      }
      if (c === '\\') { if (src[i + 1] !== '\n') append(src[i + 1] || '', false); i += 2; continue; }
      if (c === "'") { const e = src.indexOf("'", i + 1), end = e < 0 ? src.length : e; append(src.slice(i + 1, end), true); i = end + 1; continue; }
      if (c === '"') {
        let j = i + 1, piece = '';
        while (j < src.length && src[j] !== '"') {
          if (src[j] === '\\') { piece += src[j + 1] || ''; j += 2; continue; }
          if (src[j] === '$' && src[j + 1] === '(' && src[j + 2] !== '(') {
            const e = matchParen(src, j + 1);
            if (e < 0) { j = src.length; break; }
            substitute(j + 2, e); piece += '$S'; j = e + 1; continue;
          }
          if (src[j] === '\x60') { const e = src.indexOf('\x60', j + 1); if (e < 0) { j = src.length; break; } substitute(j + 1, e); piece += '$S'; j = e + 1; continue; }
          piece += src[j++];
        }
        append(piece, true); i = j + 1; continue;
      }
      if (c === '#' && !word) { while (i < src.length && src[i] !== '\n') i++; continue; }
      if (c === '<' && src[i + 1] === '<' && src[i + 2] !== '<') {
        const m = /^<<-?[ \t]*(['"]?)(\w+)\1/.exec(src.slice(i));
        if (m) { heredocs.push(m[2]); endWord(); i += m[0].length; continue; }
      }
      if (c === '\n') {
        endCommand(); i++;
        while (heredocs.length) {   // a heredoc's body is data: skip to the line holding only its delimiter
          const m = new RegExp('^[ \\t]*' + heredocs.shift() + '[ \\t]*$', 'm').exec(src.slice(i));
          i = m ? i + m.index + m[0].length : src.length;
        }
        continue;
      }
      if (c === ';' || c === '&' || c === '|' || c === '(' || c === ')') { endCommand(); i++; continue; }
      if (c === ' ' || c === '\t' || c === '\r') { endWord(); i++; continue; }
      append(c, false); i++;
    }
    endCommand();
  };
  lex(text);
  return commands;
}

// A shell text's invocations: [{ token, line }] — `line` is the command's text, which a discovering runner's
// CONVENTIONS entry reads (`--headless` or not).
function shellInvocations(text) {
  const out = [];
  for (const words of shellCommands(text)) {
    const isAssignment = (w) => !w.headQuoted && /^[A-Za-z_]\w*=/.test(w.text);
    let k = 0;
    while (k < words.length && (isAssignment(words[k]) || (!words[k].headQuoted && KEYWORDS.has(words[k].text)))) k++;
    if (k >= words.length) continue;                               // a bare assignment runs nothing
    if (!words[k].headQuoted && PRINTERS.has(words[k].text)) continue;
    const interpreter = words.findIndex((w, i) => i >= k && !w.quoted && INTERPRETERS.has(w.text));
    const launched = [];
    if (SCRIPT_TOKEN.test(words[k].text)) launched.push(words[k]);  // the program is itself a script
    SCRIPT_TOKEN.lastIndex = 0;
    if (interpreter >= 0) launched.push(...words.slice(interpreter + 1));
    const line = words.map((w) => w.text).join(' ');
    for (const w of launched) for (const m of w.text.matchAll(SCRIPT_TOKEN)) out.push({ token: m[0], line });
  }
  return out;
}

// A JS text's launches: [{ token }] from require() and from the string arguments of path.join / path.resolve.
function jsLaunches(file, text) {
  const { mask } = maskJs(text, file);
  const isCode = (i) => mask[i] === 'code';
  const out = [];
  for (const m of text.matchAll(/\brequire\(\s*(['"])([^'"]+)\1\s*\)/g)) {
    if (isCode(m.index) && m[2].startsWith('.')) out.push({ required: path.resolve(path.dirname(file), m[2]) });
  }
  for (const m of text.matchAll(/\bpath\.(?:join|resolve)\s*\(/g)) {
    if (!isCode(m.index)) continue;
    let depth = 0, i = m.index + m[0].length - 1;
    for (; i < text.length; i++) {
      if (!isCode(i)) continue;
      if (text[i] === '(') depth++;
      else if (text[i] === ')' && --depth === 0) break;
    }
    const parts = [...text.slice(m.index, i + 1).matchAll(/(['"])([^'"\n]*)\1/g)].map((s) => s[2]).filter(Boolean);
    if (parts.length && /\.(?:js|sh)$/.test(parts[parts.length - 1])) out.push({ token: parts.join('/') });
  }
  return out;
}

// The bodies of fg's four leg-running functions. Each must be found: a renamed one would silently drop its legs from
// the run set, so a missing one is an ERROR. A one-line function (`fg_suite(){ …; }`) ends on its own line.
function fgRootText(fgPath) {
  const text = fs.readFileSync(fgPath, 'utf8');
  const bodies = [], missing = [];
  for (const name of FG_FUNCTIONS) {
    const found = new RegExp(`(^|\\n)${name}\\(\\)\\{`).exec(text);
    if (!found) { missing.push(name); continue; }
    const at = found.index + found[1].length - 1;   // the newline before the header (-1 at the start of the file)
    const lineEnd = text.indexOf('\n', at + 1);
    const firstLine = text.slice(at + 1, lineEnd < 0 ? text.length : lineEnd);
    const end = /}\s*(#.*)?$/.test(firstLine) ? lineEnd : text.indexOf('\n}', at + 1);
    bodies.push(text.slice(Math.max(at, 0), end < 0 ? text.length : end));
  }
  if (missing.length) throw new Error(`what-runs: ${fgPath} defines no ${missing.join(', ')} — cannot read its legs`);
  return bodies.join('\n');
}

// { files: Set<abs path>, fgPresent, why: Map<abs path, string>, how: Map<abs path, kind> } — every script the roots
// reach; `how` says how it runs: 'root'; 'launched' when ANY edge launches it (the program of a shell command, a
// script after an interpreter word, or a path.join/path.resolve launch in JS), even one first reached as a module —
// a script some runner launches is a program with an exit code, however else it is reached; else 'required' (a JS
// module) or 'discovered' (a discovering runner's convention). `why` keeps the first edge.
function runSet(layout = DEFAULT_LAYOUT) {
  const files = scriptFiles(layout);
  const known = new Set(files);
  const resolve = resolver(files);
  const discovered = {};
  for (const k of Object.keys(CONVENTIONS)) discovered[k] = files.filter((f) => CONVENTIONS[k].re.test(path.basename(f)));
  const selfTests = new Set([...discovered.selftest, ...discovered.selftestHeadless]);

  const reached = new Set(), why = new Map(), how = new Map(), queue = [];
  const add = (f, from, kind) => {
    if (!known.has(f)) return;
    if (!reached.has(f)) { reached.add(f); why.set(f, from); how.set(f, kind); queue.push(f); return; }
    if (kind === 'launched' && how.get(f) !== 'root') how.set(f, 'launched');
  };
  // one LAUNCH of `f`, by the command `line`: a convention keyed to an invoking command applies when the line matches
  const launch = (f, line, from) => {
    add(f, from, 'launched');
    for (const [k, c] of Object.entries(CONVENTIONS)) {
      if (c.onLine && path.basename(f) === c.runner && c.onLine(line)) for (const d of discovered[k]) add(d, `${path.basename(f)} (discovers ${k})`, 'discovered');
    }
  };
  const viaShell = (text, from) => {
    for (const { token, line } of shellInvocations(text)) for (const f of resolve(token)) launch(f, line, from);
  };
  // THE BUILD'S GATE TABLE (buildSystem/gates.js, which buildSystem/run-gates.js runs): each row is a launch of its
  // script, read as the command line the runner gives it from Fizzygum/ (`node <script> <args>`; a row handed the
  // build's own arguments reads as the shell's "${args[@]}"), so a convention keyed to the invoking command applies to
  // a row as to a shell line -- run-selftests.js without --headless runs the node-tier self-tests. A row's script is
  // spelled as the build's shell would spell it, relative to Fizzygum/ (`buildSystem/x.js`, `../Fizzygum-tests/
  // scripts/x.js`; `require` resolved the table's symlinks, so the relation is taken between resolved paths), and
  // resolved like every other edge, by its tail; a row naming no scanned script is an ERROR, never a gate silently
  // dropped — but a row whose script lives in the tests repo (the table's TESTS_REPO), in a layout with no tests
  // repo, launches nothing, as the runner passes it over. The table is read as it stands on disk now, like every other
  // file here, never from require's cache.
  const viaGateTable = (gatesFile, from) => {
    delete require.cache[require.resolve(gatesFile)];
    const { GATES, BUILD_ARGS, TESTS_REPO } = require(gatesFile);
    const fizzygum = fs.realpathSync(layout.fizzygum);
    const testsRepoPresent = layout.tests !== undefined && fs.existsSync(layout.tests) && fs.statSync(layout.tests).isDirectory();
    for (const row of GATES) {
      const token = path.relative(fizzygum, row.script);
      const targets = resolve(token);
      if (targets.length === 0 && !testsRepoPresent && TESTS_REPO !== undefined && row.script.startsWith(TESTS_REPO + path.sep)) continue;
      if (targets.length === 0) throw new Error(`what-runs: ${GATE_TABLE} has a row for ${row.script}, which is not a scanned script`);
      const args = row.args === BUILD_ARGS ? ['"${args[@]}"'] : row.args;
      for (const f of targets) launch(f, ['node', token, ...args].join(' '), from);
    }
  };

  const build = path.join(layout.fizzygum, 'build_it_please.sh');
  if (!fs.existsSync(build)) throw new Error(`what-runs: no ${build}`);
  reached.add(build); why.set(build, 'ROOT: the build'); how.set(build, 'root');
  const before = reached.size;
  viaShell(fs.readFileSync(build, 'utf8'), 'build_it_please.sh');
  if (reached.size === before) throw new Error('what-runs: build_it_please.sh invokes no scanned script — the reading is broken');
  if (how.get(path.join(layout.fizzygum, GATE_RUNNER)) === 'launched') viaGateTable(path.join(layout.fizzygum, GATE_TABLE), GATE_TABLE);
  const buildAndSmoke = path.join(layout.fizzygum, 'build_and_smoke.sh');
  if (fs.existsSync(buildAndSmoke)) {
    reached.add(buildAndSmoke); why.set(buildAndSmoke, 'ROOT: the build-and-smoke check'); how.set(buildAndSmoke, 'root');
    viaShell(fs.readFileSync(buildAndSmoke, 'utf8'), 'build_and_smoke.sh');
  }
  const fgPresent = fs.existsSync(layout.fg);
  if (fgPresent) viaShell(fgRootText(layout.fg), 'ROOT: fg legs');

  while (queue.length) {
    const f = queue.shift();
    const from = path.relative(path.dirname(layout.fizzygum), f);
    for (const [k, c] of Object.entries(CONVENTIONS)) {
      if (!c.onLine && path.basename(f) === c.runner) for (const d of discovered[k]) add(d, `${path.basename(f)} (discovers ${k})`, 'discovered');
    }
    if (f.endsWith('.py')) continue;
    // A SELF-TEST runs, but what it requires or launches is exercised on FIXTURES, not run as the real check: a
    // command-line gate that only its self-test loads never runs its check.
    if (selfTests.has(f)) continue;
    const text = fs.readFileSync(f, 'utf8');
    if (f.endsWith('.sh')) { viaShell(text, from); continue; }
    for (const l of jsLaunches(f, text)) {
      if (l.required) { for (const cand of [l.required, l.required + '.js', path.join(l.required, 'index.js')]) add(cand, from, 'required'); }
      else for (const t of resolve(l.token)) add(t, from, 'launched');
    }
  }
  return { files: reached, fgPresent, why, how };
}

module.exports = { CONVENTIONS, DEFAULT_LAYOUT, scriptFiles, skippedEntry, discover, runSet, shellCommands, shellInvocations,
  jsLaunches };

// `node buildSystem/lib/what-runs.js --list-scripts` prints scriptFiles(), one per line: how a shell tool reads the
// tooling's files (find_similar_code.sh, find_duplicated_code.sh), never with a `find` of its own.
if (require.main === module) {
  if (process.argv[2] !== '--list-scripts' || process.argv.length !== 3) {
    console.error('usage: node buildSystem/lib/what-runs.js --list-scripts');
    process.exit(2);
  }
  let files;
  try { files = scriptFiles(); } catch (e) { console.error('what-runs: ' + e.message); process.exit(2); }
  for (const f of files) console.log(f);
}

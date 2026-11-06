'use strict';
// what-runs.js — the one statement of WHAT RUNS: which scripts the build and the commit-point legs actually execute,
// and which files the discovering runners pick up by name. A check that nothing runs proves nothing (a self-test
// rots, a stale-name check goes stale silently, a sanction names a guard that never fires), so the two places where
// reliance on a check is written down read this:
//   - buildSystem/run-selftests.js discovers the self-tests it runs here (CONVENTIONS), and
//   - check-hand-lists.js accepts a sanction's guard only when runSet() contains it.
// Plan, measurements and the review it survived: docs/archive/unrun-checks-plan.md.
//
// THE ROOTS. Fizzygum/build_it_please.sh (every build) and, when the umbrella's local `fg` wrapper is present, the
// bodies of its fg_build / fg_suite / run_lint / run_leg functions (the presuite and gauntlet legs; all four must be
// found, or the reading is an ERROR). `fg` is in no repo, so a bare clone has the build root alone and runSet() says
// so (`fgPresent: false`); its readers then treat a commit-point-only fact as undecidable, never as false.
//
// AN EDGE IS AN INVOCATION, NOT A MENTION. A file runs another when it LAUNCHES it:
//   - shell (.sh, and fg's function bodies), read by a small lexer (shellCommands, below): a script that is the PROGRAM
//     a command executes, that follows an INTERPRETER word (node, bash, sh, python3, source, `.`), or that is ASSIGNED
//     in a command running one (`AUDIT_PRELUDE=x.js node …`). A printing command, a test, a file operation, a bare
//     assignment, a heredoc body and a comment launch nothing; a `$( … )` substitution is a command of its own;
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
// behind a profile condition counts as run. A leg of `fg` is trusted to be in a wave; `fg` is read, never executed.

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

// The discovering runners and what each picks up. `onLine`, when present, says which shell invocations of the runner
// run this kind.
const CONVENTIONS = {
  selftest:         { re: /-selftest\.js$/,          runner: 'run-selftests.js', onLine: (l) => !/--headless\b/.test(l) },
  selftestHeadless: { re: /-selftest-headless\.js$/, runner: 'run-selftests.js', onLine: (l) => /--headless\b/.test(l) },
  prelude:          { re: /-prelude\.js$/,           runner: 'preludes-install-selftest-headless.js' },
};

// Every script file the readers consider: Fizzygum's buildSystem (recursively) and top-level shell scripts, and the
// tests repo's scripts/ when present. Sorted, absolute.
function scriptFiles(layout = DEFAULT_LAYOUT) {
  const out = [];
  const walk = (dir) => {
    if (!fs.existsSync(dir)) return;
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      if (e.name.startsWith('.') || e.name === 'node_modules' || e.name === '__pycache__') continue;
      const p = path.join(dir, e.name);
      if (e.isDirectory()) walk(p);
      else if (/\.(js|sh|py)$/.test(e.name)) out.push(p);
    }
  };
  walk(path.join(layout.fizzygum, 'buildSystem'));
  if (fs.existsSync(layout.fizzygum)) {
    for (const n of fs.readdirSync(layout.fizzygum)) if (n.endsWith('.sh')) out.push(path.join(layout.fizzygum, n));
  }
  walk(path.join(layout.tests, 'scripts'));
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
// A path runs when it is the PROGRAM a command executes (`./build_it_please.sh`), when it follows an INTERPRETER word
// in the command (`node x.js`, `to 300 node x.js`, `xargs … bash x.sh`, `source x.sh`), or when it is ASSIGNED in a
// command that runs one (`AUDIT_PRELUDE=x.js node runner.js`, `PRELUDE_JS="${3:-x.js}" … node …`). A printing command
// (echo, printf, fg's ban, `:`) runs nothing, whatever it names; so does a test (`[ -f x.js ]`), a file operation or a
// bare assignment. Each `$( … )` / backtick substitution is lexed as commands of its own (its place in the word is kept
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
    if (interpreter >= 0) {
      launched.push(...words.slice(interpreter + 1));
      launched.push(...words.slice(0, k).filter(isAssignment).map((w) => ({ text: w.text.slice(w.text.indexOf('=') + 1) })));
    }
    const line = words.map((w) => w.text).join(' ');
    for (const w of launched) for (const m of w.text.matchAll(SCRIPT_TOKEN)) out.push({ token: m[0], line });
  }
  return out;
}

// A JS text's launches: [{ token }] from require() and from the string arguments of path.join / path.resolve.
function jsLaunches(file, text) {
  const { mask } = maskJs(text);
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

// { files: Set<abs path>, fgPresent, why: Map<abs path, string> } — every script the roots reach.
function runSet(layout = DEFAULT_LAYOUT) {
  const files = scriptFiles(layout);
  const known = new Set(files);
  const resolve = resolver(files);
  const discovered = {};
  for (const k of Object.keys(CONVENTIONS)) discovered[k] = files.filter((f) => CONVENTIONS[k].re.test(path.basename(f)));
  const selfTests = new Set([...discovered.selftest, ...discovered.selftestHeadless]);

  const reached = new Set(), why = new Map(), queue = [];
  const add = (f, from) => { if (known.has(f) && !reached.has(f)) { reached.add(f); why.set(f, from); queue.push(f); } };
  const viaShell = (text, from) => {
    for (const { token, line } of shellInvocations(text)) {
      for (const f of resolve(token)) {
        add(f, from);
        for (const [k, c] of Object.entries(CONVENTIONS)) {
          if (c.onLine && path.basename(f) === c.runner && c.onLine(line)) for (const d of discovered[k]) add(d, `${path.basename(f)} (discovers ${k})`);
        }
      }
    }
  };

  const build = path.join(layout.fizzygum, 'build_it_please.sh');
  if (!fs.existsSync(build)) throw new Error(`what-runs: no ${build}`);
  reached.add(build); why.set(build, 'ROOT: the build');
  const before = reached.size;
  viaShell(fs.readFileSync(build, 'utf8'), 'build_it_please.sh');
  if (reached.size === before) throw new Error('what-runs: build_it_please.sh invokes no scanned script — the reading is broken');
  const fgPresent = fs.existsSync(layout.fg);
  if (fgPresent) viaShell(fgRootText(layout.fg), 'ROOT: fg legs');

  while (queue.length) {
    const f = queue.shift();
    const from = path.relative(path.dirname(layout.fizzygum), f);
    for (const [k, c] of Object.entries(CONVENTIONS)) {
      if (!c.onLine && path.basename(f) === c.runner) for (const d of discovered[k]) add(d, `${path.basename(f)} (discovers ${k})`);
    }
    if (f.endsWith('.py')) continue;
    // A SELF-TEST runs, but what it requires or launches is exercised on FIXTURES, not run as the real check: a
    // command-line gate that only its self-test loads never runs its check.
    if (selfTests.has(f)) continue;
    const text = fs.readFileSync(f, 'utf8');
    if (f.endsWith('.sh')) { viaShell(text, from); continue; }
    for (const l of jsLaunches(f, text)) {
      if (l.required) { for (const cand of [l.required, l.required + '.js', path.join(l.required, 'index.js')]) add(cand, from); }
      else for (const t of resolve(l.token)) add(t, from);
    }
  }
  return { files: reached, fgPresent, why };
}

module.exports = { CONVENTIONS, DEFAULT_LAYOUT, scriptFiles, discover, runSet, shellCommands, shellInvocations, jsLaunches };

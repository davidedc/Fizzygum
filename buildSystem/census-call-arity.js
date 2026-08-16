#!/usr/bin/env node
// census-call-arity.js — enumerate call sites with their TOP-LEVEL argument count, across BOTH
// repos, and (--holes) list the calls that punch `undefined` through to reach a later argument.
//
// ADVISORY. Nothing here gates; `fg critique` prints its summary. This is the tool the
// constructor-conformance arc actually ran to build every phase's work list
// (docs/plans/constructor-parameter-conformance-plan.md).
//
// ⚠⚠ WHY IT EXISTS RATHER THAN A GREP. The `positional-hole` stink is a REGRESSION ALARM, not an
// inventory: its regex needs two `undefined`s adjacent on ONE line, so it reads 0 while
// single-`undefined` holes and multi-line holes stand. The arc was archived as complete on that
// reading and re-opened the same day with ~9 sites left. **Ask this scanner whether a family is
// done; never ask the gate.**
//
// A single-line comma grep is wrong in both directions: it counts commas inside string literals
// and nested calls (`Color.create(230, 230, 130)`) as separators, it counts a trailing `#`
// comment as an argument, and it cannot see the multi-line paren form — which is exactly where
// the long calls live. This joins continuation lines and counts top-level arguments only.
//
// ⚠ CoffeeScript's paren-LESS call form is the subtle one: `f (a), b` means `f(a, b)` while
// `f(a), b` means `(f(a)), b`. A scanner that skips whitespace before testing for `(` reads the
// whole call as one argument and silently classifies an 8-argument site as a 1-argument one.
//
// Usage:
//   node buildSystem/census-call-arity.js StringWdgt TextWdgt [--min=3]   # `new X` sites
//   node buildSystem/census-call-arity.js --super=ButtonWdgt,LabelButtonWdgt   # subclass supers
//   node buildSystem/census-call-arity.js --call=add,addMenuItem [--min=4]     # METHOD calls
//   node buildSystem/census-call-arity.js --call=add --holes                   # just the holes
//   node buildSystem/census-call-arity.js --holes                              # EVERY hole, tree-wide
//
// --holes reports any call with a bare `undefined` in NON-FINAL argument position (a trailing
// `undefined` is not a hole — it is just an omitted argument spelled out). With no class/--call
// filter it sweeps every call site in both repos, which is the honest "am I done" question.
//
// Scans: Fizzygum/src/**/*.coffee, Fizzygum-tests/tests/**/*.js (a macro source is CoffeeScript
// inside a JS template literal, so the same tokenizer works), Fizzygum-tests/Automator-and-test-
// harness-src (the harness is .coffee and lives in the OTHER repo — a grep rooted at Fizzygum/src
// cannot see it, which is how a P6 miss set the wallpaper to `undefined` after every test), and
// Fizzygum-tests/scripts.

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const ROOTS = [
  path.join(ROOT, 'Fizzygum', 'src'),
  path.join(ROOT, 'Fizzygum-tests', 'tests'),
  path.join(ROOT, 'Fizzygum-tests', 'Automator-and-test-harness-src'),
  path.join(ROOT, 'Fizzygum-tests', 'scripts'),
];

const args = process.argv.slice(2);
const minArgs = Number((args.find(a => a.startsWith('--min=')) || '--min=0').slice(6));
const superOf = (args.find(a => a.startsWith('--super=')) || '').slice(8);
const callOf = (args.find(a => a.startsWith('--call=')) || '').slice(7);
const classes = args.filter(a => !a.startsWith('--'));
const holesOnly = args.includes('--holes');

function walk(dir, acc) {
  if (!fs.existsSync(dir)) return acc;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    if (e.name === 'node_modules' || e.name === '.git' || e.name === 'automation-assets') continue;
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (e.name.endsWith('.coffee') || e.name.endsWith('.js')) acc.push(p);
  }
  return acc;
}

// Split an argument text into TOP-LEVEL arguments: commas inside (), [], {} or string literals
// don't separate. Returns the list of trimmed argument sources.
function topLevelArgs(text) {
  const out = [];
  let depth = 0, quote = null, cur = '', esc = false;
  for (const ch of text) {
    if (esc) { cur += ch; esc = false; continue; }
    if (quote) {
      cur += ch;
      if (ch === '\\') esc = true;
      else if (ch === quote) quote = null;
      continue;
    }
    if (ch === '"' || ch === "'" || ch === '`') { quote = ch; cur += ch; continue; }
    if (ch === '(' || ch === '[' || ch === '{') depth++;
    if (ch === ')' || ch === ']' || ch === '}') depth--;
    if (ch === ',' && depth === 0) { out.push(cur.trim()); cur = ''; continue; }
    cur += ch;
  }
  if (cur.trim()) out.push(cur.trim());
  return out;
}

// Gather the argument text of a call starting at `idx` (just past the callee name).
// Handles both the paren form `X(a, b)` and CoffeeScript's paren-less form `X a, b`, where the
// call runs to end of line PLUS any continuation lines (a line ending in a comma, or a following
// line indented deeper that starts inside an unclosed bracket).
function callArgText(lines, li, col) {
  let rest = lines[li].slice(col);
  // ⚠ whitespace is significant: `X(a, b)` is a paren call, `X (a), b` is the paren-less form
  // with a parenthesised FIRST ARGUMENT (CoffeeScript reads `f (a), b` as `f(a, b)`). Testing
  // /^\s*\(/ conflates them and reports an 8-argument call as 1 argument.
  const paren = /^\(/.test(rest);
  let text = '', depth = 0, started = false, quote = null, esc = false, inComment = false;
  let i = li;
  while (i < lines.length) {
    const line = i === li ? rest : '\n' + lines[i];
    inComment = false;   // a `#` comment ends at the newline
    for (const ch of line) {
      if (esc) { text += ch; esc = false; continue; }
      if (quote) {
        text += ch;
        if (ch === '\\') esc = true; else if (ch === quote) quote = null;
        continue;
      }
      if (ch === '"' || ch === "'" || ch === '`') { quote = ch; text += ch; continue; }
      // A trailing `#` comment is not an argument. The long calls annotate EVERY slot with one
      // (`undefined, # @fontName`), so counting them splits one argument into two and inflates
      // arity — PointerWdgt read as 17 arguments when it passes 8.
      if (ch === '#') { inComment = true; }
      if (inComment) continue;
      if (paren) {
        if (ch === '(') { depth++; started = true; if (depth === 1) { continue; } }
        else if (ch === ')') { depth--; if (depth === 0) return { text, endLine: i }; }
      } else {
        if (ch === '(' || ch === '[' || ch === '{') depth++;
        if (ch === ')' || ch === ']' || ch === '}') { if (depth === 0) return { text, endLine: i }; depth--; }
      }
      text += ch;
    }
    // end of a physical line
    if (!paren && depth === 0) {
      const trimmed = lines[i].replace(/#.*$/, '').trimEnd();
      const next = lines[i + 1];
      const continues = /,\s*$/.test(trimmed) ||
        (next !== undefined && /^\s+/.test(next) && /^[^\s].*[,(]\s*$/.test('') === false && /,\s*$/.test(trimmed));
      if (!continues) return { text, endLine: i };
    }
    i++;
  }
  return { text, endLine: lines.length - 1 };
}

const files = ROOTS.flatMap(r => walk(r, []));
const rows = [];

for (const p of files) {
  const src = fs.readFileSync(p, 'utf8');
  const lines = src.split('\n');
  for (let li = 0; li < lines.length; li++) {
    const line = lines[li];
    if (/^\s*(#|\/\/)/.test(line)) continue;   // whole-line comment
    const patterns = superOf
      ? [new RegExp('\\bsuper\\b', 'g')]
      : (holesOnly && !callOf && !classes.length)
        // tree-wide hole sweep: any identifier followed by an argument list. Over-matches (it
        // catches non-calls too); the `undefined`-in-non-final-position filter below is what
        // makes the output meaningful, and a non-call cannot have one.
        ? [/(?<!new\s)\b[A-Za-z_$][A-Za-z0-9_$]*\b(?!\s*:)/g]
      : callOf
        // a METHOD call: `x.name`, `@name` or a bare `name`, but NOT its own `name:` DEFINITION
        // and not `new Name` (that is the --class mode).
        ? callOf.split(',').map(c => new RegExp('(?<!new\\s)\\b' + c + '\\b(?!\\s*:)', 'g'))
        : classes.map(c => new RegExp('\\bnew\\s+' + c + '\\b', 'g'));
    for (const re of patterns) {
      let m;
      while ((m = re.exec(line)) !== null) {
        const col = m.index + m[0].length;
        const { text, endLine } = callArgText(lines, li, col);
        const a = topLevelArgs(text);
        rows.push({
          file: path.relative(ROOT, p), line: li + 1, endLine: endLine + 1,
          callee: m[0].replace(/\s+/g, ' '), n: a.length,
          args: a.map(s => s.replace(/\s+/g, ' ')).map(s => s.length > 46 ? s.slice(0, 43) + '...' : s),
        });
      }
    }
  }
}

// A HOLE = a bare `undefined` argument that is NOT the last one. A TRAILING `undefined` is not a
// hole: nothing is being reached past, the caller merely spelled out an omission.
// ⚠ EXCLUDED: `fn.call undefined, x` / `.apply` / `.bind` — there `undefined` is the THIS-ARG of a
// foreign (language) API, the ordinary idiom for "no receiver", not a skipped parameter. Counting
// them buries the real holes: they are ~90 of the ~115 raw hits in this tree.
const FOREIGN_THISARG = /^(call|apply|bind)$/;
const isHole = r => !FOREIGN_THISARG.test(r.callee.replace(/^.*[.@]/, '')) &&
  r.args.some((a, i) => a === 'undefined' && i < r.args.length - 1);

rows.sort((x, y) => y.n - x.n || x.file.localeCompare(y.file) || x.line - y.line);
let shown = rows.filter(r => r.n >= minArgs);
if (holesOnly) {
  shown = shown.filter(isHole);
  // ⚠ In the tree-wide mode every identifier on a line matches, so ONE physical call is reported
  // once per name in it (`_paintInLocalScope aContext, clippingRectangle, …` reports 4 times).
  // Collapse to one row per (file, line) — rows are sorted by arity descending, so the first is
  // the leftmost/outermost callee, which is the real one.
  const seen = new Set();
  shown = shown.filter(r => { const k = r.file + ':' + r.line; if (seen.has(k)) return false; seen.add(k); return true; });
}
for (const r of shown) {
  console.log(`${r.n}  ${r.file}:${r.line}${r.endLine !== r.line ? '-' + r.endLine : ''}  ${r.callee}  [ ${r.args.join(' | ')} ]`);
}
if (holesOnly) {
  console.log(`\nHOLES: ${shown.length} call site(s) pass a bare \`undefined\` in NON-FINAL position.`);
  console.log('Each one PROVES the skipped parameter is configuration, not identity (R3).');
  console.log('⚠ The `positional-hole` stink sees only the two-adjacent-`undefined` subset — this is the real count.');
} else {
  const hist = {};
  for (const r of rows) hist[r.n] = (hist[r.n] || 0) + 1;
  console.log(`\nTOTAL ${rows.length} site(s); shown ${shown.length} (>=${minArgs} args). Arity histogram:`,
    Object.keys(hist).sort((a, b) => a - b).map(k => `${k}:${hist[k]}`).join('  '));
}

'use strict';
// gate-advice-selftest.js — lib/gate-advice.js held to what it promises. Every row names ONE gate script and a rule
// that gate can FIRE — a literal `.fired(` id or an id it `declare`s, read from its code as lib/gate-rules.js gathers
// them — so a row whose rule is gone fails however the gate's lines that ask about it stand: planted on the real
// check-call-separation.js, a guard on a line of its own beside a renamed rule, and on check-stinks.js a table entry
// renamed. Every row has a class with a shared text, a head and a body. A run's advice is one ADVICE header per
// distinct rule, in the order given, each row's text whole on lines of its own, then each class's shared text once; no
// rule, no line. parseAdvice reads one gate's advice back COUNTED — never another gate's printed beside it — so a
// header printed twice, and a class's shared text printed twice, missing or stray, each read as such. An id with no
// row, or a gate with none, stops the gate (exit 2, ADVICE_ROW_MISSING), seen in a child process. Run by
// buildSystem/run-selftests.js on every build.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const { adviceLines, parseAdvice, ADVICE_LINE_RE, ROWS, CLASSES } = require('./gate-advice');
const { readRules } = require('./gate-rules');
const { maskJs } = require('./js-mask');
const { scriptFiles } = require('./what-runs');
const t = require('./selftest-verdict').cases('gate-advice');

const LIB = path.join(__dirname, 'gate-advice.js');
const HEADER = new RegExp(ADVICE_LINE_RE.source);
const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// from the bracket at `open`, the index just past the one that closes it, counting every bracket kind in CODE
function closing(text, mask, open) {
  let depth = 0;
  for (let i = open; i < text.length; i++) {
    if (mask[i] !== 'code') continue;
    if ('([{'.includes(text[i])) depth++;
    else if (')]}'.includes(text[i]) && --depth === 0) return i + 1;
  }
  return text.length;
}

// The rule ids a gate's code can FIRE, gathered as lib/gate-rules.js gathers a gate's rule set: every literal `.fired(`
// id (its own readRules), and every id the gate `declare`s — each string of a `.declare(` call's arguments and, where an
// argument maps a table (`rules.declare(STINKS.map((s) => s.id))`), each string of that table's initializer. A line
// that asks which rules fired (`rules.firedIds.has('X')`) or asks for their advice fires none, wherever it stands.
function firableIds(text) {
  const { mask } = maskJs(text);
  const ids = new Set(readRules(text).literal);
  const spans = [];
  for (const m of text.matchAll(/\.declare\s*\(/g)) {
    if (mask[m.index] !== 'code') continue;
    const open = m.index + m[0].length - 1;
    const end = closing(text, mask, open);
    spans.push([open, end]);
    for (const table of text.slice(open, end).matchAll(/\b([A-Za-z_$][\w$]*)\s*\.\s*map\s*\(/g)) {
      const def = [...text.matchAll(new RegExp(`\\b(?:const|let|var)\\s+${esc(table[1])}\\s*=\\s*[[{]`, 'g'))]
        .find((d) => mask[d.index] === 'code');
      if (def) { const at = def.index + def[0].length - 1; spans.push([at, closing(text, mask, at)]); }
    }
  }
  for (const m of text.matchAll(/(['"])([A-Za-z0-9][\w.-]*)\1/g)) {
    if (mask[m.index] === 'str' && spans.some(([a, b]) => m.index >= a && m.index < b)) ids.add(m[2]);
  }
  return ids;
}
const STALE_ROW = 'its gate cannot fire it (no `.fired(` id, nothing it declares): the rule is gone, or renamed — delete or rename the row';

// ---- every row names one gate, a rule it can fire, and a class with a shared text
const scripts = scriptFiles();
const gateFile = (gate) => scripts.filter((f) => f.endsWith('.js') && path.basename(f, '.js') === gate);
for (const [gate, rows] of Object.entries(ROWS)) {
  const files = gateFile(gate);
  if (!t.check(files.length === 1, `${gate}: the rows name one gate script`, `${files.length} scripts named ${gate}.js: ${files.join(', ')}`)) continue;
  const text = fs.readFileSync(files[0], 'utf8');
  const { mask } = maskJs(text, files[0]);
  t.check([...text.matchAll(/\badviceLines\s*\(/g)].some((m) => mask[m.index] === 'code'),
    `${gate}: the gate prints advice (it calls adviceLines)`, files[0]);
  const firable = firableIds(text);
  for (const [id, row] of Object.entries(rows)) {
    t.check(firable.has(id), `${gate} ${id}: the row names a rule its gate can fire`, STALE_ROW);
    t.check(Object.prototype.hasOwnProperty.call(CLASSES, row.class) && typeof row.head === 'string' && row.head.trim() !== '' &&
      typeof row.body === 'string' && row.body.trim() !== '',
      `${gate} ${id}: the row has a class with a shared text, a head and a body`, JSON.stringify(row));
  }
}

// ---- a row whose rule is gone is stale however the lines that ask about it stand: planted on the real gates' text
{
  const text = fs.readFileSync(gateFile('check-call-separation')[0], 'utf8');
  // the guard choosing the advice on a line of its own, apart from the call that asks for it
  const guardAlone = text.replace(/(if \(rules\.firedIds\.has\('U_QUERY_SELF_ONLY'\)\) \{) (console\.error\(''\);) /, "$1\n    $2\n    ");
  // …and the rule's fire site renamed: only the guard and the advice call still name the row's id
  const renamed = guardAlone.replace("rules.fired('U_QUERY_SELF_ONLY', ", "rules.fired('U_QUERY_GONE', ");
  t.check(guardAlone !== text && renamed !== guardAlone, 'the plants apply to check-call-separation.js', 'a replacement matched nothing: re-read the plant against the gate');
  t.check(firableIds(guardAlone).has('U_QUERY_SELF_ONLY'), 'a guard on a line of its own leaves a rule its gate fires alive');
  t.check(!firableIds(renamed).has('U_QUERY_SELF_ONLY'),
    "a row whose rule is renamed, named only by a guard on a line of its own and by the advice call, is stale", STALE_ROW);
}
{
  const text = fs.readFileSync(gateFile('check-stinks')[0], 'utf8');
  const renamed = text.replace("{ id: 'timer', ", "{ id: 'timer-gone', ");
  t.check(renamed !== text && !firableIds(renamed).has('timer') && firableIds(renamed).has('timer-gone'),
    "a row whose rule's entry in a declared table is renamed is stale, and the new entry is a rule", STALE_ROW);
}

// ---- composition: one header per distinct rule in the order given, each row whole, then each class's text once
const G = Object.keys(ROWS).find((g) => Object.keys(ROWS[g]).length >= 2);
const [A, B] = Object.keys(ROWS[G]);
const lines = adviceLines(G, [A, B, A]);
const headers = lines.map((l, i) => [l.match(HEADER), i]).filter(([m]) => m);
t.check(headers.map(([m]) => m[2]).join() === [A, B].join() && headers.every(([m]) => m[1] === G),
  'one ADVICE header per distinct rule, in the order given, each naming its gate', headers.map(([m]) => m[0]).join(' | '));
t.check(lines.every((l) => HEADER.test(l) || l.startsWith(`[${G}] `) || l.startsWith('    ')),
  'every line is a header of its own or an indented continuation, never text after a violation', lines.join('\n'));
const shared = lines.map((l, i) => [l, i]).filter(([l]) => l.startsWith(`[${G}] `) && !HEADER.test(l));
t.check(shared.length === 1 && shared[0][1] > headers[headers.length - 1][1],
  "the class's shared text is printed once, after every rule's row", shared.map(([l]) => l).join(' | '));
const textOf = (from, to) => lines.slice(from, to).map((l, k) => (k === 0 ? l.replace(HEADER, '') : l.trim())).join(' ');
t.check(textOf(headers[0][1], headers[1][1]) === `${ROWS[G][A].head} ${ROWS[G][A].body}` &&
        textOf(headers[1][1], shared[0][1]) === `${ROWS[G][B].head} ${ROWS[G][B].body}`,
  "each row's text is printed whole, broken at spaces only", textOf(headers[0][1], headers[1][1]));
const sharedText = lines.slice(shared[0][1]).map((l, k) => (k === 0 ? l.slice(`[${G}] `.length) : l.trim())).join(' ');
const klass = CLASSES[ROWS[G][A].class];
t.check(sharedText === [klass.head, ...klass.body].join(' '), "the class's shared text is printed whole", sharedText);
t.check(adviceLines(G, []).length === 0, 'no rule, no line');

// ---- parseAdvice: one gate's own advice, counted, never another gate's beside it
const other = Object.keys(ROWS).find((g) => g !== G);
const otherId = Object.keys(ROWS[other])[0];
const shown = (m) => [...m].map(([k, n]) => `${k}=${n}`).join(' ') || 'none';
const is = (m, want) => m.size === Object.keys(want).length && Object.entries(want).every(([k, n]) => m.get(k) === n);
const SHARED = `${ROWS[G][A].class}-shared-text`;
const out = ['a violation line', ...adviceLines(other, [otherId]), ...lines, 'the gate\'s last line'].join('\n');
const read = parseAdvice(out, G);
t.check(is(read, { [A]: 1, [B]: 1 }), "a gate's advice reads back as its rule ids, each printed once", shown(read));
const readOther = parseAdvice(out, other);
t.check(is(readOther, { [otherId]: 1 }), "another gate's advice beside it is that gate's, not this one's", shown(readOther));
t.check(parseAdvice('', G).size === 0 && parseAdvice(undefined, G).size === 0, 'no output reads as no advice');
const twice = parseAdvice([...lines, ...lines].join('\n'), G);
t.check(is(twice, { [A]: 2, [B]: 2, [SHARED]: 2 }), "advice printed twice reads as each header twice, and the class's shared text twice", shown(twice));
const perRule = parseAdvice([...adviceLines(G, [A]), ...adviceLines(G, [B])].join('\n'), G);
t.check(is(perRule, { [A]: 1, [B]: 1, [SHARED]: 2 }), "advice asked for once per rule reads as the class's shared text twice", shown(perRule));
const noShared = parseAdvice(lines.slice(0, shared[0][1]).join('\n'), G);
t.check(is(noShared, { [A]: 1, [B]: 1, [SHARED]: 0 }), "rows printed without their class's shared text read as it missing", shown(noShared));
const stray = parseAdvice(lines.slice(shared[0][1]).join('\n'), G);
t.check(is(stray, { [SHARED]: 1 }), 'a shared text printed with no row of its class reads as stray', shown(stray));

// ---- an id with no row, or a gate with none, stops the gate
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'gate-advice-selftest-'));
process.on('exit', () => fs.rmSync(dir, { recursive: true, force: true }));
function child(gate, id) {
  const file = path.join(dir, `asks-advice-${gate}.js`);
  fs.writeFileSync(file, `'use strict';\nrequire(${JSON.stringify(LIB)}).adviceLines(${JSON.stringify(gate)}, [${JSON.stringify(id)}]);\nconsole.log('PRINTED NO STOP');\n`);
  const r = spawnSync(process.execPath, [file], { encoding: 'utf8' });
  return { status: r.status, out: `${r.stdout}${r.stderr}` };
}
{
  const r = child(G, 'NO_SUCH_RULE');
  t.check(r.status === 2 && new RegExp(`^\\[${esc(G)}\\] ADVICE_ROW_MISSING NO_SUCH_RULE — `, 'm').test(r.out) && !/PRINTED NO STOP/.test(r.out),
    'an id with no row stops the gate: exit 2, ADVICE_ROW_MISSING naming it', `exit ${r.status}: ${r.out}`);
}
{
  const r = child('no-such-gate', A);
  t.check(r.status === 2 && /^\[no-such-gate\] ADVICE_ROW_MISSING /m.test(r.out) && !/PRINTED NO STOP/.test(r.out),
    'a gate with no rows stops the same way', `exit ${r.status}: ${r.out}`);
}

t.done();

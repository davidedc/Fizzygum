'use strict';
// gate-advice-selftest.js — lib/gate-advice.js held to what it promises. Every row names ONE gate script, which prints
// advice, and rules that gate can FIRE — each id of its key a literal `.fired(` id or an id it `declare`s, read from
// its code as lib/gate-rules.js gathers them (a case-qualified id, its rule), and no id in two rows of one gate — so a
// row whose rule is gone fails however the gate's lines that ask about it stand: planted on the real
// check-call-separation.js, a guard on a line of its own beside a renamed rule, and on check-stinks.js a table entry
// renamed; a table the suite runner declares bare, built from lib/gate-tokens.js's exports, is its rules only while it
// is declared — and holds only what its own initializer holds, never a string after it nor a table an element only
// computes from — and a kind the menu sweep reads back from its own text is a rule only while a literal of it stands.
// Each check-stinks row is a budget's exactly while its stink's baseline is above zero, read from the STINKS table:
// planted, a budget tightened to zero and a hard rule raised above it each read as a mismatch. A
// gate's `*` row names no rule: it serves every id no other row of the gate names, under one header, beside the named
// rows. Every row has a class with a shared text, a head and a body; every class's shared text opens with a head of
// its own. A run's advice is one ADVICE header per row, in the order its first id is given, naming every id given that
// it serves (and none it was not given), each row's text whole on lines of its own, then each class's shared text
// once; no rule, no line. parseAdvice reads one gate's advice back COUNTED — never another gate's printed beside it —
// so a header printed twice, a shared row printed under a header per rule, and a class's shared text printed twice,
// missing or stray, each read as such. advisedAmong keeps the fired ids that carry a row. A rule and its
// case-qualified id are two rows. An id with no row, or a gate with none, stops the gate (exit 2,
// ADVICE_ROW_MISSING), seen in a child process. Run by buildSystem/run-selftests.js on every build.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const { adviceLines, advisedAmong, parseAdvice, ADVICE_LINE_RE, ROWS, CLASSES, ANY } = require('./gate-advice');
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
// argument maps a table (`rules.declare(STINKS.map((s) => s.id))`) or takes its values
// (`rules.declare(Object.values(MEMBER_RULE))`), each string of that table's initializer. Two declarations read what
// the gate reads: a table named bare (`rules.declare(LISTED_TOKENS)`) whose initializer holds a table a module exports
// (`const { GATE_TOKENS } = require('./lib/gate-tokens')`, `file` the gate's path, to resolve it by) holds that table's
// strings, read from the module; and kinds the gate reads back from its own text by a regex
// (`readFileSync(__filename …).matchAll(/kind: '([A-Z_]+)'/g)`) are that regex's matches in the text. A line that asks
// which rules fired (`rules.firedIds.has('X')`) or asks for their advice fires none, wherever it stands.
function firableIds(text, file) {
  const { mask } = maskJs(text);
  const ids = new Set(readRules(text).literal);
  const spans = [];
  const defOf = (name) => [...text.matchAll(new RegExp(`\\b(?:const|let|var)\\s+${esc(name)}\\s*=\\s*`, 'g'))]
    .find((d) => mask[d.index] === 'code');
  // the strings a module the gate requires exports under `name`, by the gate's own destructuring of its require
  const imported = (name) => {
    const req = [...text.matchAll(/\b(?:const|let|var)\s*\{([^}]*)\}\s*=\s*require\(\s*(['"])(\.{1,2}\/[^'"]+)\2\s*\)/g)]
      .find((r) => mask[r.index] === 'code' && r[1].split(',').map((s) => s.trim()).includes(name));
    if (!req || !file) return [];
    const value = require(path.resolve(path.dirname(file), req[3]))[name];
    return typeof value === 'string' ? [value] : value && typeof value[Symbol.iterator] === 'function' ? [...value].filter((v) => typeof v === 'string') : [];
  };
  for (const m of text.matchAll(/\.declare\s*\(/g)) {
    if (mask[m.index] !== 'code') continue;
    const open = m.index + m[0].length - 1;
    const end = closing(text, mask, open);
    const span = text.slice(open, end);
    spans.push([open, end]);
    for (const table of span.matchAll(/\b([A-Za-z_$][\w$]*)\s*\.\s*map\s*\(|\bObject\s*\.\s*values\s*\(\s*([A-Za-z_$][\w$]*)\s*\)/g)) {
      const def = defOf(table[1] || table[2]);
      if (def && '[{'.includes(text[def.index + def[0].length])) { const at = def.index + def[0].length; spans.push([at, closing(text, mask, at)]); }
    }
    // a table declared bare: only the table its own initializer IS — a literal, or one built by `new X(…)` — and, of
    // the names in it, only those standing as its elements (`[...GATE_TOKENS, UNCAUGHT_PAGE_ERROR]`), never one an
    // element only computes from (`GATE_TOKENS.filter(…)`)
    const bare = /^\(\s*([A-Za-z_$][\w$]*)\s*\)$/.exec(span);
    const def = bare && defOf(bare[1]);
    const opens = def && /^(?:new\s+[A-Za-z_$][\w$]*\s*)?[([{]/.exec(text.slice(def.index + def[0].length));
    if (opens) {
      const at = def.index + def[0].length;
      const init = text.slice(at, closing(text, mask, at + opens[0].length - 1));
      spans.push([at, at + init.length]);
      for (const el of init.matchAll(/[[,(]\s*(?:\.\.\.\s*)?([A-Za-z_$][\w$]*)\s*(?=[,\])])/g)) for (const id of imported(el[1])) ids.add(id);
    }
    const own = /readFileSync\s*\(\s*__filename\b[\s\S]*?\.matchAll\(\s*\/((?:\\.|[^/\\\n])+)\/([a-z]*)\s*\)/.exec(span);
    if (own) for (const k of text.matchAll(new RegExp(own[1], own[2].includes('g') ? own[2] : own[2] + 'g'))) if (k[1]) ids.add(k[1]);
  }
  for (const m of text.matchAll(/(['"])([A-Za-z0-9][\w.-]*)\1/g)) {
    if (mask[m.index] === 'str' && spans.some(([a, b]) => m.index >= a && m.index < b)) ids.add(m[2]);
  }
  return ids;
}
const STALE_ROW = 'its gate cannot fire it (no `.fired(` id, nothing it declares): the rule is gone, or renamed — delete or rename the row';

// ---- every row names one gate, rules it can fire (each id in one row), and a class with a shared text
const scripts = scriptFiles();
const gateFile = (gate) => scripts.filter((f) => f.endsWith('.js') && path.basename(f, '.js') === gate);
// the rule an id names: the id, or the rule a case-qualified id (`OVER_BASELINE.at-zero`) qualifies
const ruleOf = (id) => id.split('.')[0];
for (const [gate, rows] of Object.entries(ROWS)) {
  const files = gateFile(gate);
  if (!t.check(files.length === 1, `${gate}: the rows name one gate script`, `${files.length} scripts named ${gate}.js: ${files.join(', ')}`)) continue;
  const text = fs.readFileSync(files[0], 'utf8');
  const { mask } = maskJs(text, files[0]);
  t.check([...text.matchAll(/\badviceLines\s*\(/g)].some((m) => mask[m.index] === 'code'),
    `${gate}: the gate prints advice (it calls adviceLines)`, files[0]);
  const firable = firableIds(text, files[0]);
  const seen = new Map();   // id -> the row key that first named it
  for (const [key, row] of Object.entries(rows)) {
    // the `*` row names no rule: it serves the ids its gate asks for that no other row names
    const ids = key === ANY ? [] : key.split(' ');
    t.check(key === ANY || (ids.every((id) => HEADER.test(`[${gate}] ADVICE ${id} — x`)) && !/  |^ | $/.test(key)),
      `${gate} '${key}': the row's key is ids separated by single spaces, or \`${ANY}\``, key);
    for (const id of ids) {
      t.check(firable.has(ruleOf(id)), `${gate} ${id}: the row names a rule its gate can fire`, STALE_ROW);
      t.check(!seen.has(id), `${gate} ${id}: one row serves it`, `also in '${seen.get(id)}'`);
      seen.set(id, key);
    }
    t.check(Object.prototype.hasOwnProperty.call(CLASSES, row.class) && typeof row.head === 'string' && row.head.trim() !== '' &&
      typeof row.body === 'string' && row.body.trim() !== '',
      `${gate} '${key}': the row has a class with a shared text, a head and a body`, JSON.stringify(row));
  }
}
// ---- a stink's row is written for its LIVE baseline: a budget's (class C) exactly while the baseline is above zero, so
// a stink tightened to zero cannot go on printing a raise for a hard rule, nor a hard rule's text survive a raise
// each stink's baseline, read from check-stinks.js's STINKS table as written (`{ id: '<id>', baseline: <n>, …`)
function stinkBaselines(text) {
  const { mask } = maskJs(text);
  const out = new Map();
  for (const m of text.matchAll(/\{\s*id:\s*'([^']+)',\s*baseline:\s*(\d+)/g)) if (mask[m.index] === 'code') out.set(m[1], +m[2]);
  return out;
}
// the stinks whose row's class disagrees with their baseline, each said; and the row ids naming a stink whose baseline
// the read found nowhere (the check would then be blind to it)
function stinkClassMismatches(text) {
  const baselines = stinkBaselines(text);
  const mismatched = [];
  const unread = [];
  for (const [key, row] of Object.entries(ROWS['check-stinks'] || {})) {
    for (const id of key.split(' ')) {
      if (!/[a-z]/.test(id)) continue;   // a rule of the gate's own (SANCTION_COUNT), not a stink
      if (!baselines.has(id)) { unread.push(id); continue; }
      if ((row.class === 'C') !== (baselines.get(id) > 0)) mismatched.push(`${id} (baseline ${baselines.get(id)}, row class ${row.class})`);
    }
  }
  return { mismatched, unread };
}
{
  const text = fs.readFileSync(gateFile('check-stinks')[0], 'utf8');
  const real = stinkClassMismatches(text);
  t.check(!real.mismatched.length && !real.unread.length,
    "each check-stinks row is a budget's exactly while its stink's baseline is above zero",
    `${real.mismatched.join('; ') || 'no mismatch'}; unread: ${real.unread.join(' ') || 'none'}`);
  // planted on the real table: a budget tightened to zero, a hard rule raised above it
  const tightened = text.replace("{ id: 'math-random', baseline: 4,", "{ id: 'math-random', baseline: 0,");
  const raised = text.replace("{ id: 'debugger-statement', baseline: 0,", "{ id: 'debugger-statement', baseline: 1,");
  const t1 = stinkClassMismatches(tightened).mismatched;
  const t2 = stinkClassMismatches(raised).mismatched;
  t.check(tightened !== text && t1.length === 1 && /^math-random \(baseline 0, row class C\)$/.test(t1[0]),
    'a budget stink tightened to zero, its row still a budget\'s, is a mismatch', t1.join('; ') || 'none');
  t.check(raised !== text && t2.length === 1 && /^debugger-statement \(baseline 1, row class A\)$/.test(t2[0]),
    "a hard stink raised above zero, its row still a hard rule's, is a mismatch", t2.join('; ') || 'none');
}

// each class's shared text opens with a line no other class's does: that line is what parseAdvice counts
{
  const openings = Object.values(CLASSES).map((c) => c.head);
  t.check(new Set(openings).size === openings.length && Object.values(CLASSES).every((c) => c.body.length > 0),
    "every class's shared text has a head of its own and a body", openings.join(' | '));
}

// ---- a row whose rule is gone is stale however the lines that ask about it stand: planted on the real gates' text
{
  const text = fs.readFileSync(gateFile('check-call-separation')[0], 'utf8');
  // a guard asking whether the rule fired, and an advice call naming it, each on lines of their own
  const guardAlone = text.replace(/\n(\s*)process\.exit\(1\);/,
    "\n$1if (rules.firedIds.has('U_QUERY_SELF_ONLY')) {\n$1  console.error('');\n$1  for (const l of adviceLines(rules.gate, ['U_QUERY_SELF_ONLY'])) console.error(l);\n$1}\n$1process.exit(1);");
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
// a table declared bare, its strings a module's: the suite runner's gate tokens, from lib/gate-tokens.js
{
  const file = gateFile('run-all-headless')[0];
  const text = fs.readFileSync(file, 'utf8');
  const undeclared = text.replace('.declare(LISTED_TOKENS)', '');
  t.check(undeclared !== text && firableIds(text, file).has('PAINT_ERROR') && firableIds(text, file).has('UNCAUGHT_PAGE_ERROR') &&
    !firableIds(undeclared, file).has('PAINT_ERROR'),
    "a table declared bare holds the strings the module it is built from exports, and only while it is declared", STALE_ROW);
  // a bare name bound to no table of its own: a string after its declaration is no rule of it
  const elsewhere = firableIds("const IDS = OTHER;\nconsole.log('NOT_A_RULE');\nrules.declare(IDS);\n", file);
  t.check(!elsewhere.has('NOT_A_RULE'), 'a table declared bare holds only what its own initializer holds, never a string after it',
    [...elsewhere].join(' '));
  // a module's table an element only computes from is not the declared table's
  const computed = firableIds("const { GATE_TOKENS } = require('./lib/gate-tokens');\nconst IDS = new Set([...GATE_TOKENS.filter((t) => t)]);\nrules.declare(IDS);\n", file);
  t.check(!computed.has('PAINT_ERROR'), "a module's table an element only computes from adds none of its strings", [...computed].join(' '));
}
// kinds a gate reads back from its own text: the menu sweep's `kind: '<KIND>'` literals
{
  const text = fs.readFileSync(gateFile('menu-click-sweep-headless')[0], 'utf8');
  const renamed = text.split("kind: 'THREW'").join("kind: 'THREW_GONE'");
  t.check(renamed !== text && firableIds(text).has('THREW') && !firableIds(renamed).has('THREW') && firableIds(renamed).has('THREW_GONE'),
    'a kind a gate reads back from its own text is a rule while a literal of it stands', STALE_ROW);
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

// ---- a row several rules share prints once, its header naming the ids asked for, in the order given
{
  const [SG, SKEY] = Object.entries(ROWS).flatMap(([g, rows]) => Object.keys(rows).filter((k) => k.split(' ').length >= 3).map((k) => [g, k]))[0];
  const [X, Y, Z] = SKEY.split(' ');
  const solo = Object.keys(ROWS[SG]).find((k) => !k.includes(' ') && ROWS[SG][k] !== ROWS[SG][SKEY]);
  t.check(!!solo, `${SG}: holds a row several rules share and a row of one rule`, Object.keys(ROWS[SG]).join(' | '));
  const asked = [Y, solo, X, Y];
  const out2 = adviceLines(SG, asked);
  const heads = out2.filter((l) => HEADER.test(l)).map((l) => l.match(HEADER)[2]);
  t.check(heads.join(' | ') === [`${Y} ${X}`, solo].join(' | '),
    'a shared row prints one header, at its first id given, naming every id given that it serves, in that order', heads.join(' | '));
  const at = out2.findIndex((l) => HEADER.test(l));
  const next = out2.findIndex((l, i) => i > at && HEADER.test(l));
  const sharedRowText = out2.slice(at, next).map((l, k) => (k === 0 ? l.replace(HEADER, '') : l.trim())).join(' ');
  t.check(sharedRowText === `${ROWS[SG][SKEY].head} ${ROWS[SG][SKEY].body}`, "the shared row's text is printed whole, once", sharedRowText);
  t.check(heads.every((h) => !h.split(' ').includes(Z)), 'an id the row serves that was not asked for is not named', heads.join(' | '));
  const readShared = parseAdvice(out2.join('\n'), SG);
  t.check(is(readShared, { [X]: 1, [Y]: 1, [solo]: 1 }), 'a shared row reads back as each id it named, once', shown(readShared));
  // the row asked for once per rule — two headers for one row — reads as that row printed twice
  const perId = [...adviceLines(SG, [X]), ...adviceLines(SG, [Y])].join('\n');
  const ROWKEY = `${SKEY.split(' ').join('+')}-row`;
  const readPerId = parseAdvice(perId, SG);
  t.check(readPerId.get(X) === 1 && readPerId.get(Y) === 1 && readPerId.get(ROWKEY) === 2,
    'a shared row printed under a header per rule reads as the row printed twice, though each id prints once', shown(readPerId));
  const one = adviceLines(SG, [Z]).filter((l) => HEADER.test(l)).map((l) => l.match(HEADER)[2]);
  t.check(one.join() === Z, 'asked for one of its ids, a shared row names only that one', one.join());
}

// ---- advisedAmong: the ids among a gate's fired rules that carry a row, in their order, each once
{
  const [SG, SKEY] = Object.entries(ROWS).flatMap(([g, rows]) => Object.keys(rows).filter((k) => k.includes(' ')).map((k) => [g, k]))[0];
  const [X, Y] = SKEY.split(' ');
  const got = advisedAmong(SG, new Set([Y, 'NO_ROW_FOR_THIS', X]));
  t.check(got.join() === [Y, X].join(), 'advisedAmong keeps the fired ids that carry a row, in their order, and drops the rest', got.join());
  t.check(advisedAmong(SG, [X, X]).join() === X && advisedAmong('no-such-gate', [X]).length === 0 && advisedAmong(SG, []).length === 0,
    'advisedAmong names each id once, and none for a gate with no rows or no fired rule');
}

// ---- an id qualified by its case is a row of its own, read back under its own name
{
  const [QG, QKEY] = Object.entries(ROWS).flatMap(([g, rows]) => Object.keys(rows).filter((k) => k.split(' ').some((id) => id.includes('.'))).map((k) => [g, k]))[0] || [];
  if (t.check(!!QG, 'some row serves an id qualified by its case')) {
    const Q = QKEY.split(' ').find((id) => id.includes('.'));
    const plain = ruleOf(Q);
    const both = [...adviceLines(QG, [plain, Q])];
    const heads = both.filter((l) => HEADER.test(l)).map((l) => l.match(HEADER)[2]);
    const read = parseAdvice(both.join('\n'), QG);
    t.check(heads.length === 2 && heads[0] === plain && heads[1].split(' ')[0] === Q && read.get(Q) === 1 && read.get(plain) === 1 &&
      ROWS[QG][plain] && ROWS[QG][plain].class !== ROWS[QG][QKEY].class,
      `${QG}: a rule and its case-qualified id are two rows of two classes, each read back once`, `${heads.join(' | ')} — ${shown(read)}`);
  }
}

// ---- a `*` row serves every id no other row of its gate names: one header, in the order given, beside the named rows
{
  const [WG, wrows] = Object.entries(ROWS).find(([, rows]) => Object.prototype.hasOwnProperty.call(rows, ANY)) || [];
  if (t.check(!!WG, `some gate holds a \`${ANY}\` row`)) {
    const named = Object.keys(wrows).find((k) => k !== ANY).split(' ')[0];
    const asked = ['BITE_PROOF_ANY_A', named, 'BITE_PROOF_ANY_B'];
    const out3 = adviceLines(WG, asked);
    const heads = out3.filter((l) => HEADER.test(l)).map((l) => l.match(HEADER)[2]);
    t.check(heads.join(' | ') === ['BITE_PROOF_ANY_A BITE_PROOF_ANY_B', named].join(' | '),
      `${WG}: the \`${ANY}\` row prints one header naming every id no other row names, and a named row serves its own`, heads.join(' | '));
    const at = out3.findIndex((l) => HEADER.test(l));
    const next = out3.findIndex((l, i) => i > at && HEADER.test(l));
    const anyText = out3.slice(at, next).map((l, k) => (k === 0 ? l.replace(HEADER, '') : l.trim())).join(' ');
    t.check(anyText === `${wrows[ANY].head} ${wrows[ANY].body}`, `the \`${ANY}\` row's text is printed whole, once`, anyText);
    const readAny = parseAdvice(out3.join('\n'), WG);
    t.check(is(readAny, { BITE_PROOF_ANY_A: 1, BITE_PROOF_ANY_B: 1, [named]: 1 }), `the \`${ANY}\` row reads back as each id it named, once`, shown(readAny));
    const perId = parseAdvice([...adviceLines(WG, ['BITE_PROOF_ANY_A']), ...adviceLines(WG, ['BITE_PROOF_ANY_B'])].join('\n'), WG);
    t.check(perId.get(`${ANY}-row`) === 2, `the \`${ANY}\` row printed under a header per id reads as the row printed twice`, shown(perId));
    t.check(advisedAmong(WG, ['BITE_PROOF_ANY_A', named]).join() === named,
      `advisedAmong keeps the ids a row names, never one only the \`${ANY}\` row serves (its gate passes those)`,
      advisedAmong(WG, ['BITE_PROOF_ANY_A', named]).join());
  }
}

// ---- an id with no row, or a gate with none, stops the gate
const dir =fs.mkdtempSync(path.join(os.tmpdir(), 'gate-advice-selftest-'));
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

'use strict';
// macro-sources-selftest.js — the macro-source readers' cases (lib/macro-sources.js), in memory. A test's command file:
// a main source written as a string literal, null extras, and the refusals. A CoffeeScript file's verbs: each
// Macro.fromString literal in file order, cooked, from the file line its text starts on (whatever the heredoc's shape);
// a reference argument passed over; a file that never names fromString not lexed; the shapes a line-regex reader
// misreads (a `'''` heredoc, a closing `"""` on a content line, the call named in a string or a comment), the shapes a
// whole-file parse or a bare-`\n` rule misreads (blanks after an opener, CRLF, a BOM, a bare `super`); and the
// refusals — an interpolated argument, a line break written as an escape (a continuation's included), a file that does
// not lex. Run by buildSystem/run-selftests.js on every build.

const { testMacroSourcesIn, verbMacroSourcesIn } = require('./macro-sources');
const t = require('./selftest-verdict').cases('macro-sources');

// A TEST'S COMMAND FILE, as the page compiles it: a main source written as a string literal is its text,
// and an extraSubroutineSources of `null` is none; and the refusals — each naming the file and the line, never a
// source read by a guess
const read = (text) => { try { return { sources: testMacroSourcesIn(text, 'f.js') }; } catch (e) { return { refusal: e.message }; } };
const plain = read('var c = { "mainMacroSource": "m()", "extraSubroutineSources": null };\n');
t.check(!!plain.sources && plain.sources.map((s) => s.role + ':' + s.text).join(' ') === 'main:m()',
  `a string-literal main source is read, and null extras are none (${plain.refusal || JSON.stringify(plain.sources)})`);
for (const [what, text, expect] of [
  ['a source holding a `${…}`', 'var c = { "mainMacroSource": `a ${b}` };\n', /^MACRO_SOURCE_UNREADABLE: f\.js:1 — its main source is neither a string literal nor a template literal without/],
  ['a source that is a name, not a literal', 'var c = {\n "extraSubroutineSources": [`x()`, helper] };\n', /^MACRO_SOURCE_UNREADABLE: f\.js:2 — its extra source is neither a string literal nor a template literal without/],
  ['an extraSubroutineSources that is no array (the page would compile its characters)', 'var c = { "mainMacroSource": `m()`,\n "extraSubroutineSources": `one()` };\n', /^MACRO_SOURCE_UNREADABLE: f\.js:2 — its extraSubroutineSources is no array/],
  ['a source writing a line break as an escape', 'var c = {\n "mainMacroSource": `a\\nb` };\n', /^MACRO_SOURCE_UNREADABLE: f\.js:2 — its main source writes a line break as an escape/],
  // a written \n and a \⏎ in one source: the line COUNT still matches, every line after them sits one line off
  ['a source whose `\\n` and `\\⏎` cancel out', 'var c = {\n "mainMacroSource": `a = "x\\ny"\nlong = 1 + \\\n2` };\n', /^MACRO_SOURCE_UNREADABLE: f\.js:2 — its main source writes a line break as an escape/],
]) {
  const r = read(text);
  t.check(!!r.refusal && expect.test(r.refusal), `${what} is refused, naming the file and line (${r.refusal || 'read as ' + JSON.stringify(r.sources)})`);
}

// A COFFEESCRIPT FILE'S VERBS: each `Macro.fromString` string literal, as { role: 'verb', line, text }
const verbs = (lines) => { try { return { sources: verbMacroSourcesIn(lines.join('\n'), 'f.coffee') }; } catch (e) { return { refusal: e.message }; } };
const shown = (r) => r.refusal || r.sources.map((s) => `${s.line}:${JSON.stringify(s.text)}`).join(' ');
const Q3 = '"""';
for (const [what, lines, want] of [
  ['a heredoc opened at a line end: its text from the next line, dedented, its closing indent no line of it',
    ['class K', '  v: ->', `    Macro.fromString ${Q3}`, '      a_Macro = ->', '', '        @x()', `    ${Q3}`, '  w: ->', `    Macro.fromString ${Q3}`, '      b()', `    ${Q3}`],
    '4:"a_Macro = ->\\n\\n  @x()" 10:"b()"'],
  ["a '''-heredoc", ['v = ->', "  Macro.fromString '''", '    a()', "  '''"], '3:"a()"'],
  ['a heredoc whose text starts on its opening line, and one closing on a content line',
    ['v = ->', `  Macro.fromString ${Q3}a()`, '    b()', `  ${Q3}`, `  Macro.fromString ${Q3}`, `    c()${Q3}`, '  d = 1'], '2:"a()\\nb()" 6:"c()"'],
  ['a heredoc whose text starts with a blank line', ['v = ->', `  Macro.fromString ${Q3}`, '', '    a()', `  ${Q3}`], '3:"\\na()"'],
  ['an escape that keeps the lines', ['v = ->', `  Macro.fromString ${Q3}`, '    r = /\\\\d/', `  ${Q3}`], '3:"r = /\\\\d/"'],
  ['a plain string', ['v = -> Macro.fromString "a()"'], '1:"a()"'],
  ["a reference argument (the harness compiling a test's sources) is no source of this file",
    ['run = (eachSource) ->', '  Macro.fromString eachSource', '  Macro.fromString @mainMacroSource'], ''],
  ['the call named in a string or a comment is no call',
    ['v = ->', '  log "Macro.fromString \\"\\"\\" is how a verb is written"', `  # Macro.fromString ${Q3}`, '  x()'], ''],
]) {
  const r = verbs(lines);
  t.check(shown(r) === want, `${what} (${shown(r)})`);
}
// the shapes a whole-file reading or a bare-`\n` rule gets wrong: a blank opening line holding blanks, CRLF line breaks,
// a BOM before a verb on line 1, and a file only the fragment compiler accepts (a bare `super`) — a comment naming the
// call in it, and a verb beside it
const cases2 = [
  ['an opening line holding blanks after its `"""`', [`v = ->`, `  Macro.fromString ${Q3}  `, '    a()', `  ${Q3}`], '3:"a()"'],
  ["an opening line holding a tab after its `'''`", ['v = ->', "  Macro.fromString '''\t", '    a()', "  '''"], '3:"a()"'],
  ['CRLF line breaks', ['v = ->\r', `  Macro.fromString ${Q3}\r`, '    a()\r', '    b()\r', `  ${Q3}\r`], '3:"a()\\nb()"'],
  ['a BOM before a verb on line 1', [`﻿Macro.fromString ${Q3}`, '  a()', Q3], '2:"a()"'],
  ['a file only the fragment compiler accepts, a comment naming the call in it',
    ['class A extends B', '  m: ->', '    super', '    # Macro.fromString is how a verb is made', '    x()'], ''],
  ['a file only the fragment compiler accepts, a verb in it',
    ['class A extends B', '  m: ->', '    super', `    Macro.fromString ${Q3}`, '      a()', `    ${Q3}`], '5:"a()"'],
];
for (const [what, lines, want] of cases2) {
  const r = verbs(lines);
  t.check(shown(r) === want, `${what} (${shown(r)})`);
}
t.check(verbs(['x = "unclosed']).sources.length === 0, 'a file that never names fromString is not lexed: its text, unlexable or not, holds no verb');
for (const [what, lines, expect] of [
  ['an interpolated argument', ['v = (n) ->', `  Macro.fromString ${Q3}`, '    #{n}()', `  ${Q3}`],
    /^MACRO_SOURCE_UNREADABLE: f\.coffee:2 — a Macro\.fromString argument computed when the page runs/],
  ['a line break written as an escape', ['v = ->', `  Macro.fromString ${Q3}`, '    a = "x\\ny"', `  ${Q3}`],
    /^MACRO_SOURCE_UNREADABLE: f\.coffee:3 — its verb source writes a line break as an escape/],
  ['a line continuation', ['v = ->', `  Macro.fromString ${Q3}`, '    a = 1 + \\', '    2', `  ${Q3}`],
    /^MACRO_SOURCE_UNREADABLE: f\.coffee:3 — its verb source writes a line break as an escape/],
  ['two arguments', ['v = -> Macro.fromString "a()", 2'], /^MACRO_SOURCE_UNREADABLE: f\.coffee:1 — a Macro\.fromString given 2 arguments/],
  ['a continuation with blanks after its backslash, beside a written line break', ['v = ->', `  Macro.fromString ${Q3}`, '    a = "x\\ny"', '    b = 1 + \\  ', '    2', `  ${Q3}`],
    /^MACRO_SOURCE_UNREADABLE: f\.coffee:3 — its verb source writes a line break as an escape/],
  ['a file naming fromString that does not lex', ['v = ->', '  Macro.fromString "a()"', '  x = "unclosed', ''], /^MACRO_SOURCE_UNREADABLE: f\.coffee:\d+ — it names fromString and does not lex/],
]) {
  const r = verbs(lines);
  t.check(!!r.refusal && expect.test(r.refusal), `${what} is refused, naming the file and line (${shown(r)})`);
}

t.done();

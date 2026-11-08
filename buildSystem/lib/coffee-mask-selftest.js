'use strict';
// coffee-mask-selftest.js — the masker's cases (lib/coffee-mask.js): each a CoffeeScript text and what one of its
// lines reads as — its code (comment blanked), its bare code (literal contents blanked too) and its comment. The cases
// are the readings a hand-rolled cut gets wrong: a `#` or a quote inside a string, a regex, a heregex or a JS
// passthrough; interpolation code, and a comment inside a multi-line interpolation; a heredoc's `#` lines; a heregex's
// comments; a string spanning lines; a `###` block; a BOM and \r; a text the lexer refuses. And the record's own
// facts: a string's text is 'str', any other literal's 'lit'; which lines continue a literal; one reading per text.
// Run by buildSystem/run-selftests.js on every build.

const { coffeeMask, isCommentOnly } = require('./coffee-mask');
const t = require('./selftest-verdict').cases('coffee-mask');

// line `n` (0-based) of `text`: its code, bare and comment views
function read(text, n) { const r = coffeeMask(text, 'case')[n]; return r; }
function expectLine(what, text, n, want) {
  let r;
  try { r = read(text, n); } catch (e) { t.check(false, what, 'threw ' + e.message); return; }
  for (const view of Object.keys(want)) {
    t.check(r[view] === want[view], `${what} — ${view}`, `got ${JSON.stringify(r[view])}, want ${JSON.stringify(want[view])}`);
  }
}

expectLine('a trailing comment is cut', 'f() # note', 0, { code: 'f()       ', bare: 'f()       ', comment: '# note' });
expectLine('a `#` inside a string is the string\'s', 'x = "a # b"; y()', 0, { code: 'x = "a # b"; y()', bare: 'x = "     "; y()', comment: undefined });
expectLine('an interpolation is code, its string is not', 'x = "a#{f()}b" # c', 0, { code: 'x = "a#{f()}b"    ', bare: 'x = "   f()  "    ', comment: '# c' });
expectLine('a string inside an interpolation is a literal of its own', 'x = "#{f("q")}"', 0, { bare: 'x = "  f(" ") "' });
expectLine('a `#` inside a regex is the regex\'s', 'r = /#\\d/; g()', 0, { code: 'r = /#\\d/; g()', bare: 'r = /   /; g()', comment: undefined });
expectLine('a quote inside a regex opens nothing', 'r = /"/g; g() # c', 0, { bare: 'r = / / ; g()    ', comment: '# c' });
expectLine('a heregex holding \'\'\' opens no heredoc', "r = ///'''///\ng() # c", 1, { code: 'g()    ', comment: '# c' });
expectLine('an interpolated heregex keeps its code', 'r = ///a#{b}c///g', 0, { bare: 'r = ///   b  /// ' });
expectLine('a JS passthrough holding `#` is a literal', 'x = `a # b`; g()', 0, { bare: 'x = `     `; g()', comment: undefined });
expectLine('a heredoc\'s `#` line is heredoc text', 's = """\n  # not a comment\n  """\ng() # c', 1, { code: '  # not a comment', bare: '                 ', comment: undefined });
expectLine('…and the code after the heredoc is code', 's = """\n  # not a comment\n  """\ng() # c', 3, { code: 'g()    ', comment: '# c' });
expectLine('a "…" string spanning lines holds its `#`', 's = "a\n b # c"\nz()', 1, { code: ' b # c"', comment: undefined });
expectLine('a `###` block is a comment, line by line', '###\n  x()\n###\ny()', 1, { code: '     ', bare: '     ', comment: '  x()' });
expectLine('…and the code after it is code', '###\n  x()\n###\ny()', 3, { code: 'y()', comment: undefined });
expectLine('`####` opens a line comment, not a block', '#### a\ny()', 1, { code: 'y()' });
expectLine('a call given a literal reads as given an argument', '@verb "left button", t', 0, { bare: '@verb "           ", t' });
expectLine('a BOM is laid back, code at column 0', '﻿a = 1 # c', 0, { code: '﻿a = 1    ', comment: '# c' });
expectLine('a \\r is laid back in its column', 'a = 1 # c\r\nb = "#" # d\r', 1, { code: 'b = "#"     ', comment: '# d\r' });

expectLine('a heregex\'s `# …` is a comment', 'r = ///\n  abc  # inner comment\n///', 1, { code: '  abc' + ' '.repeat(17), comment: '# inner comment' });
expectLine('a comment inside a multi-line interpolation is a comment', 's = """\n  a #{\n    f(x) # inner\n  } b\n  """', 2, { bare: '    f(x)        ', comment: '# inner' });

// a string's text is 'str', a regex's and a JS passthrough's 'lit'; the code between an interpolation's braces 'code'
const kinds = coffeeMask('x = "s#{ y }" + /r/ + `j`')[0].mask.map((c) => c[0]).join('');
t.check(kinds === 'ccccsssscccssccclllccclll', "'str' for a string, 'lit' for a regex and a JS passthrough, 'code' inside #{ }", kinds);

// which lines continue a literal an earlier line opened: a heredoc's body (an empty line too) and its closing line do;
// a line that merely begins with a literal does not
const cont = coffeeMask('s = """\n  a\n\n  """\n/x#y/.test(z)\n"q".length');
t.check(JSON.stringify(cont.map((l) => l.continuesLiteral)) === JSON.stringify([false, true, true, true, false, false]),
  'continuesLiteral: the heredoc\'s lines do, a line opening with a regex or a string does not', JSON.stringify(cont.map((l) => l.continuesLiteral)));

// one reading per text: the same records, however many readers ask
const once = 'a = 1 # c';
t.check(coffeeMask(once, 'a reader') === coffeeMask(once, 'another reader'), 'a text is read once per process');

// every view keeps every column
const sample = 'x = "a#{f()}b" # c\nr = /"/g\ns = """\n  #{q} # t\n  """';
t.check(coffeeMask(sample).every((r, i) => [r.code, r.bare].every((v) => v.length === sample.split('\n')[i].length) && r.mask.length === sample.split('\n')[i].length),
  'every view is as long as its line', 'a view changed a line\'s length');

// a comment-only line: a `#` line and a `###` block's line are; a code line with a comment and a heredoc's `#` line are not
const only = coffeeMask('g = ->\n  # marker: why\n  f() # c\ns = """\n  # heredoc text\n  """\n###\n  block\n###');
t.check(JSON.stringify(only.map(isCommentOnly)) === JSON.stringify([false, true, false, false, false, false, true, true, true]),
  'isCommentOnly: a # line and a ### block are; code with a comment and a heredoc # line are not', JSON.stringify(only.map(isCommentOnly)));

// a text the lexer refuses is refused, by place
let refusal;
try { coffeeMask('x = 1\ny = "open', 'Some.coffee'); } catch (e) { refusal = e.message; }
t.check(/^COFFEE_MASK_UNLEXABLE Some\.coffee:2 — /.test(refusal || ''), 'an unlexable text is refused with its place', `got ${refusal}`);

t.done();

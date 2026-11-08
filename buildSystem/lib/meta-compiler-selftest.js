'use strict';
// meta-compiler-selftest.js — the meta-system's super rewrite (src/meta/Class.coffee `rewriteSuperCalls`, reached by
// Class's and Mixin's `_rewriteSuperCalls`), loaded and run the way every build tool runs it: through
// lib/meta-compiler.js, whose shim must hand it the bundled compiler's lexer. One case per reading:
// - each form, read from the tokens and never from the text after the keyword (a trailing space before a comment, a
//   postfix `if`, an operator, a tab, an implicit object on the next line, an empty call over two lines);
// - a `super` that is no SUPER token (a string, a comment, a regex, the end of a name) left as written, as is one each
//   accessor or soak continues, `do super`, and one in the body of a nested class;
// - a `super` in an interpolation, which is code; several on one line; every line kept on its line;
// - the text the lexer reads (a byte-order mark, \r — lone or before a newline);
// - a source the lexer refuses handed on as written, and any other failure propagating;
// - the mixin's run-time target, and a class compiled whole, the rewrite reaching the compiler.
// Run by buildSystem/run-selftests.js on every build.

const path = require('path');
const { loadMetaCompiler } = require('./meta-compiler');
const t = require('./selftest-verdict').cases('meta-compiler');

const compiled = [];
const { CoffeeScript, Class, Mixin } = loadMetaCompiler({
  srcDir: path.join(__dirname, '..', '..', 'src'),
  compileFGCode: (src, bare) => { compiled.push(src); return CoffeeScript.compile(src, { bare }); },
});
const B = 'K.__super__.m';
const rewriteText = (text) => Class.prototype._rewriteSuperCalls.call({ name: 'K' }, 'm', text);
const expectText = (what, text, want) => {
  let got;
  try { got = rewriteText(text); } catch (e) { got = 'THREW ' + e.message; }
  t.check(got === want, what, `got ${JSON.stringify(got)}, want ${JSON.stringify(want)}`);
};
const expect = (what, body, want) => expectText(what, '(a) ->\n' + body + '\n', '(a) ->\n' + want + '\n');

// the four forms — the call the parser reads
expect('`super()` is an explicit call with no arguments', '  super()', `  ${B}.call(this)`);
expect('an explicit empty call over two lines keeps both lines, and what sits between its parentheses',
  '  super( # none\n  )\n  x()', `  ${B}.call(this # none\n  )\n  x()`);
expect('`super(a, b)` is an explicit call', '  super(a, b)', `  ${B}.call(this, a, b)`);
expect('`super a, b` is an implicit call', '  super a, b', `  ${B}.call this, a, b`);
expect('`super<tab>a` is an implicit call', '  super\ta', `  ${B}.call this,\ta`);
expect('`super` followed by an indented object is an implicit call with that object, not a forward whose result is called',
  '  x = super\n    key: a', `  x = ${B}.call this,\n    key: a`);
expect('a bare `super` forwards every argument', '  super\n  more()', `  ${B}.apply(this, arguments)\n  more()`);
expect('a bare `super` before a trailing space and a comment forwards (read as text, it looks like a call with no argument)',
  '  return super  # Path B', `  return ${B}.apply(this, arguments)  # Path B`);
expect('a bare `super` before a postfix `if` forwards', '  return super if a', `  return ${B}.apply(this, arguments) if a`);
expect('a bare `super` before an operator forwards, and the operator stays one', '  super + 1', `  ${B}.apply(this, arguments) + 1`);
expect('a bare `super` that closes a block forwards', '  if a\n    super\n  b()', `  if a\n    ${B}.apply(this, arguments)\n  b()`);

// what is no SUPER token is left as written
for (const [what, body] of [
  ['a `super` in a double-quoted string', '  say "call super later", "super()"'],
  ['a `super` in a single-quoted string', "  say 'super a'"],
  ['a `super` in a heredoc', '  say """\n    super a\n    super\n  """'],
  ['a `super` in a line comment', '  # calls super( here, then super\n  go()'],
  ['a `super` in a trailing comment', '  go() # and super()'],
  ['a `super` in a block comment', '  ###\n  super a\n  ###\n  go()'],
  ['a `super` in a regex', '  r = /super /'],
  ['a `super` in a heregex', '  r = ///super(x)///'],
  ['a name ending in `super`', '  @_super a\n  x.super()\n  o = {super: 1}'],
  // each accessor and soak, alone: the compiler refuses every one of them
  ['`super.x`', '  super.foo()'],
  ['`super?.x`', '  super?.foo'],
  ['`super::x`', '  super::foo'],
  ['`super?::x`', '  super?::foo'],
  ['`super[x]`', '  super[x]'],
  ['`super?[x]`', '  super?[0]'],
  ['`super?()`', '  super?()'],
  ['`super?`', '  super?'],
]) expect(what + ' is left as written', body, body);
expect('`do super` (the lexer places it at the `do`) is left as written, and the other `super`s are still rewritten',
  '  super a\n  do super', `  ${B}.call this, a\n  do super`);
expect("a `super` in the body of a nested class is that class's own, and is left as written",
  '  x = class Q extends R\n    m2: (x) -> super x\n  super a', `  x = class Q extends R\n    m2: (x) -> super x\n  ${B}.call this, a`);
expect("a one-line nested class's `super` is left as written too",
  '  class Q extends R then m: -> super()\n  super a', `  class Q extends R then m: -> super()\n  ${B}.call this, a`);
expect('a class with no body, its header ended by a new line, opens none: the next block is the member\'s own',
  '  x = class Q\n  f ->\n    super', `  x = class Q\n  f ->\n    ${B}.apply(this, arguments)`);
expect('a class with no body, its header ended by the end of its block, opens none either',
  '  f (->\n      x = class Q\n    ), ->\n      super', `  f (->\n      x = class Q\n    ), ->\n      ${B}.apply(this, arguments)`);

expect('a `super` in an interpolation is code', '  "#{super()}!"', `  "#{${B}.call(this)}!"`);
expect('a bare `super` in an interpolation forwards', '  "#{ super }"', `  "#{ ${B}.apply(this, arguments) }"`);
expect('several on one line are each rewritten in place', '  [super(a), super b]', `  [${B}.call(this, a), ${B}.call this, b]`);
expect('a string beside a real `super` stays as written', '  super "super docs"', `  ${B}.call this, "super docs"`);

// every line stays on its line: build tools map a member's lines back onto its file by that
const many = '  super a\n  # super\n  x = super\n    k: 1\n  "super"\n  super(\n  )\n  return super if a';
t.check(rewriteText('(a) ->\n' + many + '\n').split('\n').length === ('(a) ->\n' + many + '\n').split('\n').length,
  'every line of the source stays on its line');

// the text the lexer reads: it drops a byte-order mark and every \r, so the tokens sit on that text
expectText('a byte-order mark is dropped, and the `super` after it rewritten', '﻿(a) -> super a', `(a) -> ${B}.call this, a`);
expectText('CRLF line endings are read as the lexer reads them', '(a) ->\r\n  super a\r\n', `(a) ->\n  ${B}.call this, a\n`);
expect('lone \\r characters before a string holding `super` do not move the real one into it',
  '  ' + '\r'.repeat(8) + "y = ['super', super(a), '+'] # ']", `  y = ['super', ${B}.call(this, a), '+'] # ']`);

// a source the lexer refuses is handed on as written (compileFGCode then reports that error, placed); any other
// failure is a fault, and propagates
expect('a source the lexer refuses is handed on as written', '  x = "open\n  super a', '  x = "open\n  super a');
const realTokens = CoffeeScript.tokens;
let fault = '';
CoffeeScript.tokens = () => { throw new TypeError('planted fault'); };
try { rewriteText('(a) ->\n  super a\n'); } catch (e) { fault = e.message; } finally { CoffeeScript.tokens = realTokens; }
t.check(fault === 'planted fault', `a failure that is no refusal of the lexer propagates (${fault || 'swallowed'})`);

// the mixin's target: the class the calling method was injected in, read at run time
const mixed = Mixin.prototype._rewriteSuperCalls.call({}, 'XMixin =\n  m: (a) ->\n    super a\n');
t.check(mixed === "XMixin =\n  m: (a) ->\n    window[@[arguments.callee.name + '_class_injected_in']].__super__[arguments.callee.name].call this, a\n",
  `a mixin's super calls the class the method was injected in (${JSON.stringify(mixed)})`);

// a class compiled whole through the meta-compiler: the rewritten member is what reaches the compiler
compiled.length = 0;
let threw = '';
try { new Class('class K2 extends Object\n  m: (a) ->\n    super a # see super docs\n    "call super later"\n', true, false); }
catch (e) { threw = e.message; }
const member = compiled.find((s) => s.includes('call super later')) || '';
t.check(!threw && member.includes('K2.__super__.m.call this, a # see super docs') && member.includes('"call super later"'),
  `the meta-compiler hands the compiler each member with its super calls rewritten, and nothing else (${threw || JSON.stringify(member)})`);

t.done();

'use strict';
// meta-compiler-selftest.js — the meta-system's super rewrite (src/meta/Class.coffee `rewriteSuperCalls`, reached by
// Class's `_rewriteSuperCalls`), loaded and run the way every build tool runs it: through
// lib/meta-compiler.js, whose shim must hand it the bundled compiler's lexer. One case per reading:
// - each form, read from the tokens and never from the text after the keyword (a trailing space before a comment, a
//   postfix `if`, an operator, a tab, an implicit object on the next line, an empty call over two lines);
// - a `super` that is no SUPER token (a string, a comment, a regex, the end of a name) left as written, as is one each
//   accessor or soak continues, `do super`, and one in the body of a nested class;
// - a `super` in an interpolation, which is code; several on one line; every line kept on its line;
// - the text the lexer reads (a byte-order mark, \r — lone or before a newline);
// - a source the lexer refuses handed on as written, and any other failure propagating;
// - a class compiled whole, the rewrite reaching the compiler;
// - every constructor ending in `return` (Class.endingInReturn), each body shape read from the lexer: on lines of its
//   own at any indentation (tabs too, a last line with no new line), empty, on the arrow's line (an `if … else`,
//   deeper continuation lines, a parameter default holding an arrow, parameters over several lines, no space after
//   the arrow), an early return, a name starting `return`, a body already ending in one, a nested function's own
//   return, a comment the source opens on, BOM and CRLF; a source the lexer refuses handed on as written, and a
//   constructor that is no `->` function refused;
// - a class compiled whole: its constructor with nothing injected, and a class with no constructor given the
//   forwarding one through the same path.
// Run by buildSystem/run-selftests.js on every build.

const path = require('path');
const { loadMetaCompiler, rewriteSuper } = require('./meta-compiler');
const t = require('./selftest-verdict').cases('meta-compiler');

const compiled = [];
const { CoffeeScript, Class } = loadMetaCompiler({
  srcDir: path.join(__dirname, '..', '..', 'src'),
  compileFGCode: (src, bare) => { const js = CoffeeScript.compile(src, { bare }); compiled.push({ src, js }); return js; },
});
const B = 'K.__super__.m';
const rewriteText = (text) => rewriteSuper(Class, 'K', 'm', text);
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
expectText('a byte-order mark is dropped, and the `super` after it rewritten', '\uFEFF(a) -> super a', `(a) -> ${B}.call this, a`);
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

// a class compiled whole through the meta-compiler: the rewritten member is what reaches the compiler
compiled.length = 0;
let threw = '';
try { new Class('class K2 extends Object\n  m: (a) ->\n    super a # see super docs\n    "call super later"\n', true, false); }
catch (e) { threw = e.message; }
const member = (compiled.find((c) => c.src.includes('call super later')) || { src: '' }).src;
t.check(!threw && member.includes('K2.__super__.m.call this, a # see super docs') && member.includes('"call super later"'),
  `the meta-compiler hands the compiler each member with its super calls rewritten, and nothing else (${threw || JSON.stringify(member)})`);

// EVERY CONSTRUCTOR ENDS IN `return` (Class.endingInReturn): compiled, it hands back no last expression, so `new`
// always returns the instance. Each body shape, read from the lexer, never from the text.
const ctorJS = (source) => {
  let js;
  try { js = CoffeeScript.compile(Class.endingInReturn(source), { bare: true }); } catch (e) { js = 'THREW ' + e.message; }
  return js;
};
const returnsNothing = (what, source, wantJS) => {
  const js = ctorJS(source);
  t.check(js === wantJS, what, `got ${JSON.stringify(js)}, want ${JSON.stringify(wantJS)}`);
};
returnsNothing('a body on lines of its own ends in a return at its own column', '(a) ->\n    @x = new X\n',
  '(function(a) {\n  this.x = new X;\n});\n');
returnsNothing('a body indented deeper than the house four spaces ends in a return at its own column', '->\n      @x = {}\n',
  '(function() {\n  this.x = {};\n});\n');
returnsNothing('an empty body (parameters assigned to fields) still compiles to just them once it has moved',
  '(@parent, @children = []) ->\n\n  ',
  '(function(parent, children = []) {\n  this.parent = parent;\n  this.children = children;\n});\n');
returnsNothing('a body on the arrow\'s line moves to a line of its own and ends in a return', '(a) -> @x = {}',
  '(function(a) {\n  this.x = {};\n});\n');
returnsNothing('a one-line `if … then … else` returns from neither branch (a `; return` would bind to the else)',
  '(a) -> if a then @b() else @c()', '(function(a) {\n  if (a) {\n    this.b();\n  } else {\n    this.c();\n  }\n});\n');
returnsNothing('a one-line body that continues on deeper lines keeps them, and its nested function its own return',
  '(a) -> @f ->\n    1\n', '(function(a) {\n  this.f(function() {\n    return 1;\n  });\n});\n');
returnsNothing('a parameter default holding an arrow is not the constructor\'s arrow', '(f = ((x) -> x)) -> @f = f',
  '(function(f = (function(x) {\n    return x;\n  })) {\n  this.f = f;\n});\n');
returnsNothing('an early return in the body still leaves the fall-through returning nothing',
  '(a) ->\n    return if a\n    @x = {}\n', '(function(a) {\n  if (a) {\n    return;\n  }\n  this.x = {};\n});\n');
returnsNothing('a last line that opens with a name starting `return` is no return', '->\n    returnValue = {}\n',
  '(function() {\n  var returnValue;\n  returnValue = {};\n});\n');
returnsNothing('a body that already ends in `return` compiles to one', '->\n    @x = {}\n    return\n',
  '(function() {\n  this.x = {};\n  return;\n});\n');
returnsNothing('a nested function\'s own `return` is left alone, and nothing is added to it',
  '->\n    @p.then (r) =>\n      return if @destroyed\n      @go()\n',
  '(function() {\n  this.p.then((r) => {\n    if (this.destroyed) {\n      return;\n    }\n    return this.go();\n  });\n});\n');
returnsNothing('a byte-order mark and CRLF line endings are read as the lexer reads them', '\uFEFF(a) ->\r\n    @x = {}\r\n',
  '(function(a) {\n  this.x = {};\n});\n');
returnsNothing('a one-line body after a byte-order mark is split at the arrow the lexer placed', '\uFEFF(a) -> @x = {}',
  '(function(a) {\n  this.x = {};\n});\n');
returnsNothing('a parameter list over several lines before a one-line body: the body moves off the arrow\'s line',
  '(a,\n      b) -> @x = a', '(function(a, b) {\n  this.x = a;\n});\n');
returnsNothing('a body written right after the arrow, with no space, moves whole', '(a) ->@x = {}',
  '(function(a) {\n  this.x = {};\n});\n');
returnsNothing('a body on lines of its own whose last line ends without a new line', '->\n    @x = {}',
  '(function() {\n  this.x = {};\n});\n');
returnsNothing('a body indented with a tab takes the return at its own indentation', '->\n\t@x = {}\n',
  '(function() {\n  this.x = {};\n});\n');
returnsNothing('a comment the source opens on is no code: the function after it ends in a return',
  '# builds K\n    (a) ->\n      @x = new X\n', '// builds K\n(function(a) {\n  this.x = new X;\n});\n');
const blockSource = '(a) ->\n    super a\n    # note\n    @x = {}\n';
t.check(Class.endingInReturn(blockSource).startsWith(blockSource), 'a body on lines of its own keeps every line on its line');
t.check(Class.endingInReturn('->\n    x = "open\n') === '->\n    x = "open\n', 'a source the lexer refuses is handed on as written');
// a constructor that is no `->` function is refused, naming its class (at HEAD it compiled, and failed at eval or at
// `new`; a function its source does not open on would silently have returned its last expression)
for (const [what, source] of [
  ['a bound `=>` constructor (CoffeeScript refuses one too)', '=> @x = 1'],
  ['a value that is no function', 'someFunction'],
  ['a function the source does not open on (parenthesised)', '(->\n    @x = {}\n)'],
  ['an empty constructor value', ''],
]) {
  let refusal = '';
  try { Class.endingInReturn(source, 'K'); } catch (e) { refusal = e.message; }
  t.check(refusal.startsWith('the constructor of K is no `->` function'), `${what} is refused, naming the class (${refusal || 'not refused'})`);
}

// a class compiled whole: its constructor reaches the compiler ending in `return`, with no registration in it --
// Widget's constructor is where a widget registers, once (src/basic-widgets/Widget.coffee)
compiled.length = 0;
threw = '';
try { new Class('class K4 extends Object\n  constructor: (a) ->\n    super()\n    @p.then (r) =>\n      return if @destroyed\n      @go()\n', true, false); }
catch (e) { threw = e.message; }
const ctor4 = compiled[0] || { js: '' };
t.check(!threw && ctor4.js === '(function(a) {\n  K4.__super__.constructor.call(this);\n  this.p.then((r) => {\n    if (this.destroyed) {\n      return;\n    }\n    return this.go();\n  });\n});\n',
  `a written constructor is compiled ending in return, with nothing injected before any return (${threw || JSON.stringify(ctor4.js)})`);
// a class that writes no constructor gets the one CoffeeScript gives it: as if written `constructor: -> super`. It is
// not the source's, so the member step build tools read a source's members at (_rewriteSuperCalls) never sees it
compiled.length = 0;
threw = '';
const memberSteps = [];
const realMemberStep = Class.prototype._rewriteSuperCalls;
Class.prototype._rewriteSuperCalls = function (memberName) { memberSteps.push(memberName); return realMemberStep.apply(this, arguments); };
try { new Class('class K3 extends Object\n  m: -> 1\n', true, false); }
catch (e) { threw = e.message; }
finally { Class.prototype._rewriteSuperCalls = realMemberStep; }
const ctor3 = compiled[0] || { js: '' };
t.check(!threw && ctor3.js === '(function() {\n  K3.__super__.constructor.apply(this, arguments);\n});\n',
  `a class with no constructor gets one that forwards every argument, through the same path (${threw || JSON.stringify(ctor3.js)})`);
t.check(memberSteps.join() === 'm', `the forwarding constructor is not offered to build tools as a member of the source (member steps: ${memberSteps.join() || 'none'})`);

t.done();

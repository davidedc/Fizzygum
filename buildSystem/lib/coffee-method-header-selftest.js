'use strict';
// coffee-method-header-selftest.js — the shared method-header matcher (lib/coffee-method-header.js) held to the
// PRODUCT's reading of a class. Each member SPELLING below is written into a class between two ordinary methods, and
// the product says which members the class holds and which are methods — never a hand-written answer:
//   - the members and their lines: src/meta/Class.coffee's own parse (`_parsedSource`, loaded through
//     lib/meta-compiler.js), each member's line read off the stop its own `findUpTo` makes on `propertyRegex`, so no
//     second reading of a member line is involved;
//   - which members are METHODS: Widget.functionLiteralReading, the product's own "does this member's code open with a
//     function literal" (compiled from src/basic-widgets/Widget.coffee as the page compiles it).
// The module's contract, held on every spelling:
//   NO METHOD IS SILENTLY UNSEEN — every method of the parse is a span of methodSpans (same name, side and line), or
//     its header line is returned by unseenMethodHeaders (a build error that names its fix);
//   NO SPAN NAMES A NON-METHOD — every span is a method of the parse;
//   THE GUARD FIRES ONLY WHERE IT MUST — every line it returns heads a method of the parse that no span reads;
//   THE MATCHER READS WHAT IT PROMISES — on a spelling of its header's forms 1 and 2 (marked READ), every method is a
//     span: a guard that turned one into a build error would fail every file written that way.
// The guard's QUIET cases are judged BY HAND: each states that the guard returns nothing on one class-level line. They
// keep the guard's own false fires one by one, and the first of them is no member of any class body — its real home
// (src/boot/extensions/String-extensions.coffee) has no class line, so the product's class parse has no reading of it
// to judge by. Wherever the parse does read a line, the third check above derives the same silence.
// And the guard's two copies of where the product's member body stops are held to the product's own spelling.
//
// WHAT EACH SPELLING CATCHES — each measured by planting the narrowing into the module and running this file:
//   `foo:  -> 1` (a run of spaces)                     a matcher reading exactly one space after the colon
//   `foo:(a) ->`, `foo:-> 1` (no space)                the instance matcher reading `: +` — `foo:-> 1` as a method
//                                                      silently unseen, since no guard shape reads a line ending in no
//                                                      arrow
//   `@foo:(a) ->`, `@foo:-> 1`                         the class-side matcher reading `: +`, the same way
//   `foo: (a)->`                                       a matcher wanting a space before the arrow
//   `foo: (` (wrapped after the paren)                 a matcher without its form 2
//   `foo: (a,` / `@foo: (a,` (wrapped after a
//     parameter)                                       a guard without its (b); `foo:(a,`, also a guard whose key
//                                                      wants a space after the colon
//   `foo : (a) ->` / `@foo : (a) ->`                   a guard whose key admits no space before the colon, or without
//                                                      its (a)
//   the class side's wrapped, continued, next-line,
//     space-before-colon and `$` spellings            a guard with no class side
//   each backslash-continued header                    a guard without its (c); the two past a blank line and a
//                                                      comment, a (c) reading only the very next line
//   each value on the next line                        a guard without its (d), or whose key wants a space after the
//                                                      colon; the comment standing for a value, a (d) reading the
//                                                      value off the raw line
//   the `$` names                                      a guard whose name has no `$`, or without its (a)
//   the continued fields                               a matcher reading the backslash as a header; the one onto
//                                                      `(3 + 4) * 2`, a next-line test asking only for a leading paren
//   the fields whose value is on the next lines        a matcher reading a key with no value as a header; the one onto
//                                                      `(3 + 4) * 2`, a next-line test asking only for a leading paren
//   a key with no value before the next member, or
//     before a comment at the member indent            a next-code-line reading past the member's body, or a matcher
//                                                      reading a key with no value as a header
// The rest (the house spelling, no parameters, a bound function, a default holding a call, the class side's house
// spelling, the plain fields, a nested key) pass under every plant measured: they hold what none of those narrowings
// touches. The two stop checks fail on either stop respelled.
// Run by buildSystem/run-selftests.js on every build.
const fs = require('fs');
const path = require('path');
const H = require('./coffee-method-header');
const { methodSpans, unseenMethodHeaders } = H;
const { coffeeMask } = require('./coffee-mask');
const { loadMetaCompiler } = require('./meta-compiler');
const { SRC } = require('./source-files');
const t = require('./selftest-verdict').cases('coffee-method-header');

const { CoffeeScript, Class } = loadMetaCompiler({ srcDir: SRC, compileFGCode: () => '(function() {});' });
const parse = (text) => Class.prototype._parsedSource.call(Object.create(Class.prototype), text);

// the product's method reading, compiled from its own source: a member is a method when this answers anything
const WIDGET = path.join(SRC, 'basic-widgets', 'Widget.coffee');
const readingSource = parse(fs.readFileSync(WIDGET, 'utf8')).staticPropertiesSources.functionLiteralReading;
if (typeof readingSource !== 'string') throw new Error(`no @functionLiteralReading member in ${WIDGET}: the product's method reading moved`);
const functionLiteralReading = new Function('CoffeeScript',
  CoffeeScript.compile('reading = ' + readingSource, { bare: true }) + '\nreturn reading;')(CoffeeScript);

// the product's methods of a class text: [{ key: '<@?name>:<1-based line>', line }], each member's line found by
// tapping the real parse's own findUpTo (the member line it stops on)
function productMethods(text) {
  const proto = Class.prototype, real = proto.findUpTo, total = text.split('\n').length, lines = [];
  proto.findUpTo = function (sourceLines, stop, opts) {
    const r = real.apply(this, arguments);
    if (stop === proto.propertyRegex && !(opts && opts.orStopOn) && r) lines.push(total - r[3].length);
    return r;
  };
  let parsed;
  try { parsed = proto._parsedSource.call(Object.create(proto), text); } finally { proto.findUpTo = real; }
  const all = text.split('\n');
  return lines.map((i) => {
    const name = all[i].match(proto.propertyRegex)[1];
    const src = name[0] === '@' ? parsed.staticPropertiesSources[name.slice(1)] : parsed.nonStaticPropertiesSources[name];
    return { key: name + ':' + (i + 1), line: i + 1, isMethod: functionLiteralReading(src) !== undefined };
  }).filter((m) => m.isMethod);
}
const wrap = (body) => ['class BiteProofHeader', '', '  before: ->', '    0', '', ...body, '', '  after: ->', '    1', ''].join('\n');

// READ marks a spelling the module promises to READ (its header's forms 1 and 2): there the method must be a span — a
// guard that turns it into a build error would fail every file written that way. The method-ness stays the product's.
const READ = 'read';
const SPELLINGS = [
  ['closed, the house spelling', ['  biteProof: (a) ->', '    a'], READ],
  ['no parameters', ['  biteProof: ->', '    1'], READ],
  ['no space before the arrow', ['  biteProof: (a)->', '    a'], READ],
  ['a bound function', ['  biteProof: (a) =>', '    a'], READ],
  ['a run of spaces after the colon', ['  biteProof:  -> 1'], READ],
  ['NO space after the colon, parameters', ['  biteProof:(a) ->', '    a'], READ],
  ['NO space after the colon, no parameters', ['  biteProof:-> 1'], READ],
  ['NO space after the colon, wrapped after a parameter', ['  biteProof:(a,', '      b) ->', '    a']],
  ['a parameter default holding a call', ['  biteProof: (a = f(1)) ->', '    a'], READ],
  ['a wrapped parameter list, broken after the paren', ['  biteProof: (', '      a, b', '    ) ->', '    a'], READ],
  ['a wrapped parameter list, broken after a parameter', ['  biteProof: (a,', '      b) ->', '    a']],
  ['a header continued by a backslash', ['  biteProof: \\', '      (a, b) ->', '    a']],
  ['a header continued by a backslash onto a wrapped parameter list', ['  biteProof: \\', '      (a,', '       b) ->', '    a']],
  ['a header continued by a backslash onto a bare arrow', ['  biteProof: \\', '      -> 1']],
  ['a header continued by a backslash past a blank line', ['  biteProof: \\', '', '      (a, b) ->', '    a']],
  ['a header continued by a backslash past a comment line', ['  biteProof: \\', '      # a note', '      (a, b) ->', '    a']],
  ['a value on the next line, parameters', ['  biteProof:', '    (a) ->', '      a']],
  ['a value on the next line, no parameters', ['  biteProof:', '    -> 1']],
  ['a value on the next line, a wrapped parameter list', ['  biteProof:', '    (a,', '     b) ->', '      a']],
  ['a value on the next line, past a comment line', ['  biteProof:', '    # a note', '    (a) ->', '      a']],
  ['a comment where the value goes, the function on the next line', ['  biteProof: # a note', '    (a) ->', '      a']],
  ['a space before the colon', ['  biteProof : (a) ->', '    a']],
  ['a $ opening the name', ['  $biteProof: (a) ->', '    a']],
  ['a $ inside the name', ['  bite$Proof: (a) ->', '    a']],
  ['class side, the house spelling', ['  @biteProof: (a) ->', '    a'], READ],
  ['class side, NO space after the colon', ['  @biteProof:(a) ->', '    a'], READ],
  ['class side, NO space after the colon, no parameters', ['  @biteProof:-> 1'], READ],
  ['class side, a wrapped parameter list broken after a parameter', ['  @biteProof: (a,', '      b) ->', '    a']],
  ['class side, a header continued by a backslash', ['  @biteProof: \\', '      (a, b) ->', '    a']],
  ['class side, a value on the next line', ['  @biteProof:', '    (a) ->', '      a']],
  ['class side, a space before the colon', ['  @biteProof : (a) ->', '    a']],
  ['class side, a $ in the name', ['  @$biteProof: (a) ->', '    a']],
  ['a field', ['  biteProof: 3']],
  ['a field holding a parenthesised value', ['  biteProof: ((@grow ? 1) * 100).toString()']],
  ['a field whose name holds a $', ['  $biteProof: 3']],
  ['a field continued by a backslash', ['  biteProof: \\', '      3 + 4']],
  ['a field continued by a backslash onto a parenthesised value', ['  biteProof: \\', '      (3 + 4) * 2']],
  ['a field continued by a backslash past a blank line', ['  biteProof: \\', '', '      3 + 4']],
  ['a field whose value is on the next lines', ['  biteProof:', '    a: 1']],
  ['a field whose value on the next line is an array', ['  biteProof:', '    [1, 2]']],
  ['a field whose value on the next line is parenthesised', ['  biteProof:', '    (3 + 4) * 2']],
  ['a key with no value before the next member, a wrapped header', ['  biteProof:', '  other: (a,', '      b) ->', '    a']],
  ['a key with no value before a comment at the member indent', ['  biteProof:', '  # a note', '    (a) ->', '      a']],
  ['a class-side field', ['  @BITE_PROOF: 5']],
  ['a key nested in a method body is body', ['  biteProof: ->', '    x =', '      inner: -> 2', '    x'], READ],
];
for (const [label, body, mustRead] of SPELLINGS) {
  const text = wrap(body);
  const lines = text.split('\n');
  const product = productMethods(text);
  const spans = methodSpans(lines).map((s) => s.name + ':' + (s.line + 1));
  const guarded = unseenMethodHeaders(lines, coffeeMask(text, label)).map((u) => u.line);
  const unseen = product.filter((m) => !spans.includes(m.key) && !guarded.includes(m.line)).map((m) => m.key);
  const phantom = spans.filter((k) => !product.some((m) => m.key === k));
  const needless = guarded.filter((l) => !product.some((m) => m.line === l && !spans.includes(m.key)));
  t.check(!unseen.length, `${label}: no method of the parse is silently unseen`, `unseen [${unseen}] (spans [${spans}])`);
  t.check(!phantom.length, `${label}: every span is a method of the parse`, `phantom [${phantom}]`);
  t.check(!needless.length, `${label}: the guard returns only a method no span reads`, `returned lines [${needless}]`);
  if (mustRead) {
    const unread = product.filter((m) => !spans.includes(m.key)).map((m) => m.key);
    t.check(!unread.length, `${label}: the matcher reads it — a span, never only a build error`, `not a span [${unread}]`);
  }
}

// the guard's quiet cases, judged by hand (the header says why): a class-level line it must NOT return
const QUIET = [
  ['a prototype shorthand at the member indent', ['  String::biteProof = (a) ->', '    a']],
  ['an option key whose value is a balanced parenthesised expression', ['  biteProof: ((@grow ? 1) * 100).toString()']],
  ['a paren inside a string literal', ['  biteProof: "(open"']],
  ['a closed header it already sees', ['  biteProof:(a) ->', '    a']],
  ['a field continued by a backslash', ['  biteProof: \\', '      3 + 4']],
  ['a field continued by a backslash onto a parenthesised value', ['  biteProof: \\', '      (3 + 4) * 2']],
];
for (const [label, body] of QUIET) {
  const text = wrap(body);
  const got = unseenMethodHeaders(text.split('\n'), coffeeMask(text, label));
  t.check(!got.length, `guard quiet: ${label}`, `returned ${JSON.stringify(got)}`);
}

// the guard's copies of where the product's member body stops, held to the product's own spelling (a module that
// exports none fails here by name, never by a throw)
const sourceOf = (re) => (re instanceof RegExp ? re.source : `not a RegExp: ${re}`);
t.check(sourceOf(H.PRODUCT_MEMBER_LINE) === Class.prototype.propertyRegex.source,
  "the guard's member-line stop is spelled as the product's propertyRegex",
  `${H.PRODUCT_MEMBER_LINE} vs ${Class.prototype.propertyRegex}`);
t.check(sourceOf(H.PRODUCT_TOP_LEVEL_COMMENT) === Class.prototype.topLevelCommentRegex.source,
  "the guard's comment stop is spelled as the product's topLevelCommentRegex",
  `${H.PRODUCT_TOP_LEVEL_COMMENT} vs ${Class.prototype.topLevelCommentRegex}`);
t.done();

// coffee-method-header.js — the ONE spelling of "this line defines a class method", and the ONE
// grouping of a file's lines into methods (instance and class-side alike), shared by every build gate
// that groups a `.coffee` file into methods.
//
// WHY THIS EXISTS. Six gates each carried their own copy of
//     /^  ([A-Za-z_]\w*): (\(.*?\) )?[-=]>/
// and every copy had the same blind spot: it requires the `->` on the header LINE, so a method whose
// parameter list WRAPS is not a method header to any of them. `Widget.prompt` and a second prompt door
// were invisible to the public/private call census for as long as they had two-line signatures — the
// census simply had no record that the methods existed, and nobody could see that from its output,
// because a gate that cannot see a method reports nothing about it rather than reporting a gap.
// Found 2026-08-15 while landing P4 of docs/archive/constructor-parameter-conformance-plan.md: fitting
// the two signatures onto one line made the census's method count jump by exactly two, which is the
// only reason the blind spot surfaced at all.
//
// AND THE SAME REGEX HAD A SECOND BLIND SPOT, found by the guard below the moment it was written:
// the old spelling required a SPACE before the arrow (`(\(.*?\) )?`), so the perfectly ordinary
// `foo: (a, b)->` was invisible too — 35 methods on this tree, including `ActivePointerWdgt`'s and
// most of the layout specs' menu popouts. Two independent formatting variations, one shared regex,
// zero warnings from any of the six gates: that is the shape of the bug, not the individual spellings.
//
// AND A THIRD, found 2026-08-24 while extending check-menu-actions with RULE 1b (which needs to know
// whether a class defines a method at all): the spelling demanded EXACTLY ONE space after the colon,
// so an author aligning a short body — `softWrapOn:  -> @setSoftWrap true`, `buildWindow:  -> …` —
// hid the method from every gate. Nine methods on this tree, and the guard below could not see them
// either, because its own precondition demanded `: \S` and a second space is not `\S`. Same shape,
// third time: the matcher is written against the LANGUAGE — `:` then any run of spaces, NONE included,
// which is how the product itself reads a member line (src/meta/Class.coffee `propertyRegex`, ` *: *`)
// — never against a house formatting habit. `foo:(a) ->` is a method to the language and to the
// product, so it is one to every gate.
//
// WHAT COUNTS AS A HEADER. Either form:
//   1. closed on the line — `foo: ->`, `foo: (a, b) ->`, `foo: (a)->`, `foo: (a) =>`, `foo:  ->`,
//      `foo:(a) ->`, `foo:->`
//   2. OPENING a wrapped parameter list — `foo: (` with nothing after the paren
// Form 2's continuation lines need no special handling by the caller: they are indented deeper than
// the header (or are the closing `) ->`), so every gate's existing "is this a body line?" test already
// treats them as body, which is exactly right — they are part of the signature, not a new method.
//
// WHAT A LINE CANNOT DECIDE, and so is no header here — a member whose function starts on a LATER line:
//   - a member line CONTINUED by a backslash: `foo: \` with `(a, b) ->` on the next line;
//   - a member line with NO value, the value on the next line: `foo:` with `(a) ->` (or `-> 1`) below.
// To the language each is a method; to a line-local regex each is indistinguishable from a FIELD
// written the same way (`foo: \` with `3 + 4` next; `foo:` with `a: 1` below), so reading either line
// as a header would turn every such field into a method no file defines — a wrong method in place of a
// missing one. The guard below returns both shapes instead (its (c) and (d)): a build error whose fix
// is to write the header on one line.
//
// The alternation is deliberately spelled with the parameter list NON-capturing so the method name
// stays `m[1]` for every existing caller.
//
// ⚠ Form 2 is anchored to a bare `(` at end of line, NOT to unbalanced parens, so a field whose value
// merely starts with a paren and closes on its line (`x: (a + b) * 2`) is no header. Its stated limit:
// a FIELD whose parenthesised value opens with a bare `(` and closes on a later line (`x: (` then
// `3 + 4` then `)`) is read as a method — a span the product reads as a field, and no gate says so.
// Measured on this tree: the anchored form matches the wrapped signatures and no field.
//
// Cases: lib/coffee-method-header-selftest.js. Each member spelling there is judged against the
// product's own parse; the guard's quiet cases are judged by hand (that file's header says why).

// A 2-space-indent class method header. Name in m[1].
const METHOD_HEADER = /^  ([A-Za-z_]\w*): *(?:(?:\(.*?\)\s*)?[-=]>|\($)/;

// The CLASS-SIDE variant: a 2-space `@name:` key whose value is a function — `@forApp: (app) ->`,
// `@defaults: ->`, `@named: (` — in the same two forms. Name, without the `@`, in m[1].
const STATIC_METHOD_HEADER = /^  @([A-Za-z_]\w*): *(?:(?:\(.*?\)\s*)?[-=]>|\($)/;

// The regression guard for the blind spot itself. A wrapped signature is only visible above because
// it breaks immediately after the `(`; a caller that instead writes
//     foo: (aContext,
//       al, at) ->
// would be invisible again, and — this is the whole lesson — NOTHING would say so, because a gate
// that cannot see a method reports nothing about it. This returns those lines so a gate can FAIL on
// them, turning a silent blind spot into a build error that names its own fix.
// Returns [{ line (1-based), text }]. Four shapes, all anchored at the class-method indent, on either
// side (`  name:` and `  @name:`), each read off the VALUE — the member line's code after its colon:
//   (a) the value ends in an arrow but we did not match it — a closed header in a spelling we missed;
//   (b) the value OPENS an unbalanced paren list — a wrapped signature whose header line we missed;
//   (c) the value ends in a backslash and the member's next CODE line opens a function — a parameter
//       list closed then an arrow, a bare arrow, or an unbalanced paren list — a header continued onto a
//       later line (WHAT A LINE CANNOT DECIDE, above);
//   (d) there is NO value (nothing, or only a comment) and the member's next code line opens a function
//       — the value written on the next line (the same).
// The member's next CODE line passes over blank lines, comment-only lines and a literal's text (read off
// the masker), and stops where the product's own reading of a member's body stops: at the next member
// line or at a comment at the member indent (PRODUCT_MEMBER_LINE, PRODUCT_TOP_LEVEL_COMMENT).
// ⚠ (b) tests paren BALANCE, not merely `: (`, so it cannot fire on an option-object key whose value
// is a parenthesised expression (`defaultContents: ((@grow ? 1) * 100).toString()`) — those close on
// the line. An earlier draft of this guard omitted the balance test and flagged nine of them. It DOES
// fire on a field whose call wraps (`x: f(a,` then `b)`), either side: loud, never a silent miss.
// ⚠ (c) and (d) ask the next code line for a function's OPENING (OPENS_A_FUNCTION) or for (b)'s
// unbalanced list, never merely for a leading paren, so a field written onto an ordinary value passes
// (`x: \` then `3 + 4`, or then `(3 + 4) * 2`; `x:` then `a: 1`). One whose next code line opens a call
// that closes on a later line (`x:` then `f(1,` then `2)`) reads as a header — as for (b), a loud
// error on a field, never a silent miss of a method.
// ⚠ The key admits a SPACE before the colon (`name : ->`) precisely so such a line reaches the shapes
// and FAILS the gate: that spelling is a third header variation METHOD_HEADER does not match, found live
// on 13 methods by the 2026-08-18 dispatch-slot census — and an earlier precondition (`\w*: \S`)
// skipped those lines entirely, making the guard blind to exactly the bug class it exists to catch.
// The canonical spelling is colon flush against the name.
// ⚠ It admits any run of spaces after the colon, NONE included, for the mirror-image reason: the guard
// must reach every line the matchers read, or a spelling both miss reaches neither. An earlier `: \S`
// made the guard blind to the aligned `softWrapOn:  ->` spelling, which METHOD_HEADER itself could not
// see either — nine methods checked by no gate, silently, until 2026-08-24.
// ⚠ It reads the CLASS side too (`@?`), and skips a line either matcher sees: a class-side method in a
// spelling STATIC_METHOD_HEADER misses is invisible to every gate exactly as an instance one is.
// ⚠ Its name admits a `$` (as the language's and the product's do); the matchers' does not, so a `$`
// name is a build error here, never a silent miss. The matchers keep `[A-Za-z_]\w*` because their
// readers build regexes from method names unescaped (lib/settle-tiers.js, lib/repaint-verbs.js).
// ⚠ `(?!:)` keeps it off a prototype shorthand written at the member indent —
// `  String::getNthPositionInStringBeforeOrAfter = (…) ->` (src/boot/extensions/String-extensions.coffee)
// — which ends in an arrow and is no member of any class body.
// `masked` is the file's lib/coffee-mask.js reading: the key, the arrow, the parens and the backslash are read off its
// bare code, so neither a comment nor a literal (`label: "(open"`) can open a list, end in an arrow or continue a line.
const MEMBER_KEY = /^  @?[A-Za-z_$][\w$]*\s*:(?!:)/;
const OPENS_A_FUNCTION = /^\s*(?:\(.*?\)\s*)?[-=]>/;   // a line that begins a function: `(a, b) ->`, `->`
// Where the product's reading of a member's body stops (src/meta/Class.coffee getSourceOfAllProperties): the next
// member line (its `propertyRegex`) or a comment at the member indent (its `topLevelCommentRegex`). Spelled as the
// product spells them, and held to its spelling by the self-test.
const PRODUCT_MEMBER_LINE = /^  (@?[a-zA-Z_$][0-9a-zA-Z_$]*) *: *(.*)/;
const PRODUCT_TOP_LEVEL_COMMENT = /^  #.*/;
function parenDepth(code) {
  let depth = 0;
  for (const ch of code) { if (ch === '(') depth++; else if (ch === ')') depth--; }
  return depth;
}
// the bare code of the next CODE line of the member whose key is on line i, or undefined when its body ends first
function nextCodeLine(lines, masked, i) {
  for (let j = i + 1; j < lines.length; j++) {
    if (PRODUCT_MEMBER_LINE.test(lines[j]) || PRODUCT_TOP_LEVEL_COMMENT.test(lines[j])) return undefined;
    if (masked[j].bare.trim() !== '') return masked[j].bare;
  }
  return undefined;
}
const opensAFunction = (code) => code !== undefined && (OPENS_A_FUNCTION.test(code) || parenDepth(code) > 0);
function unseenMethodHeaders(lines, masked) {
  const out = [];
  lines.forEach((raw, i) => {
    const code = masked[i].bare;
    const key = MEMBER_KEY.exec(code);
    if (!key) return;                                                        // a class-level key, either side
    if (METHOD_HEADER.test(raw) || STATIC_METHOD_HEADER.test(raw)) return;   // …and not one we can already see
    const value = code.slice(key[0].length);
    if (/[-=]>\s*$/.test(value)                                                     // (a)
        || parenDepth(value) > 0                                                    // (b)
        || (/\\\s*$/.test(value) && opensAFunction(nextCodeLine(lines, masked, i)))  // (c)
        || (value.trim() === '' && opensAFunction(nextCodeLine(lines, masked, i)))) // (d)
      out.push({ line: i + 1, text: raw.trim() });
  });
  return out;
}

// THE GROUPING ITSELF — what a line does to "which method am I in". A method is a 2-space key of a
// class body; a key written deeper — inside an object literal, or a def nested in a method's body — is
// body to this grouping, never a method of its own. So a member that lives anywhere but a class body is
// seen by no gate, and a gate that cannot see a method reports nothing about it (§6b of
// lint-and-static-checks.md): every home of a member is a class.
//   A CLASS-SIDE key (`  @name:`) bounds a method exactly as an instance key does: a class-side METHOD
// is a header of its own, and any other class-side key ENDS the method above it. Without that rule a
// static method's body reads as the tail of the instance method written above it, so a gate attributes
// what the static does to a method that does not do it. A class-side header is reported under the name
// `@name`, its source spelling, and flagged `static: true`: a gate keying by name can never mistake it
// for an instance method of the same name, and a gate that is about instance methods only skips it by
// the flag.
//   Returns { method, kind: 'header' | 'end', static } when the line STARTS or ENDS a method (`static`
// on headers only), null for a body line. The grouping is METHOD_HEADER's and STATIC_METHOD_HEADER's —
// except that a 2-space non-method key (instance or class-side) or a column-0 line ENDS the method
// (kind 'end') instead of being folded into the one above it. It reads a RAW line, so a caller skips the
// lines that continue a literal (lib/coffee-mask.js `continuesLiteral`), as check-layering and the two
// censuses do: fed a heredoc's line at column 0, it ends the method the heredoc sits in.
function methodBoundary(raw) {
  const m = raw.match(METHOD_HEADER);
  if (m) return { method: m[1], kind: 'header', static: false };
  const cm = raw.match(STATIC_METHOD_HEADER);
  if (cm) return { method: '@' + cm[1], kind: 'header', static: true };
  if (/^  @?[A-Za-z_]\w*:/.test(raw) || /^[^\s]/.test(raw)) return { method: null, kind: 'end' };
  return null;
}

// Every method of a file as a span: [{ name, line (0-based header index), end (exclusive), static }],
// `static` true for a class-side method (named `@name` — see methodBoundary). The span a gate scans as
// "this method's body" is lines line+1 .. end-1.
function methodSpans(lines) {
  const spans = [];
  let open = null;
  lines.forEach((raw, i) => {
    const b = methodBoundary(raw);
    if (!b) return;
    if (open) { open.end = i; spans.push(open); open = null; }
    if (b.kind === 'header') open = { name: b.method, line: i, end: lines.length, static: b.static };
  });
  if (open) spans.push(open);
  return spans;
}

module.exports = {
  METHOD_HEADER, STATIC_METHOD_HEADER, methodBoundary, methodSpans, unseenMethodHeaders,
  PRODUCT_MEMBER_LINE, PRODUCT_TOP_LEVEL_COMMENT,
};

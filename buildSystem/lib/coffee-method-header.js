// coffee-method-header.js — the ONE spelling of "this line defines a class method", shared by every
// build gate that groups a `.coffee` file into methods.
//
// WHY THIS EXISTS. Six gates each carried their own copy of
//     /^  ([A-Za-z_]\w*): (\(.*?\) )?[-=]>/
// and every copy had the same blind spot: it requires the `->` on the header LINE, so a method whose
// parameter list WRAPS is not a method header to any of them. `Widget.prompt` and `Widget.textPrompt`
// were invisible to the public/private call census for as long as they had two-line signatures — the
// census simply had no record that the methods existed, and nobody could see that from its output,
// because a gate that cannot see a method reports nothing about it rather than reporting a gap.
// Found 2026-08-15 while landing P4 of docs/plans/constructor-parameter-conformance-plan.md: fitting
// the two signatures onto one line made the census's method count jump by exactly two, which is the
// only reason the blind spot surfaced at all.
//
// AND THE SAME REGEX HAD A SECOND BLIND SPOT, found by the guard below the moment it was written:
// the old spelling required a SPACE before the arrow (`(\(.*?\) )?`), so the perfectly ordinary
// `foo: (a, b)->` was invisible too — 35 methods on this tree, including `ActivePointerWdgt`'s and
// most of the layout specs' menu popouts. Two independent formatting variations, one shared regex,
// zero warnings from any of the six gates: that is the shape of the bug, not the individual spellings.
//
// WHAT COUNTS AS A HEADER. Either form:
//   1. closed on the line — `foo: ->`, `foo: (a, b) ->`, `foo: (a)->`, `foo: (a) =>`
//   2. OPENING a wrapped parameter list — `foo: (` with nothing after the paren
// Form 2's continuation lines need no special handling by the caller: they are indented deeper than
// the header (or are the closing `) ->`), so every gate's existing "is this a body line?" test already
// treats them as body, which is exactly right — they are part of the signature, not a new method.
//
// The alternation is deliberately spelled with the parameter list NON-capturing so the method name
// stays `m[1]` (and `m[2]` for the mixin variant) for every existing caller.
//
// ⚠ Form 2 is anchored to a bare `(` at end of line, NOT to unbalanced parens, so it cannot swallow a
// class-level FIELD whose value happens to start with a paren. Measured on this tree: the anchored
// form matches exactly the 10 wrapped signatures and nothing else, at both indents.

// A 2-space-indent class method header. Name in m[1].
const METHOD_HEADER = /^  ([A-Za-z_]\w*): (?:(?:\(.*?\)\s*)?[-=]>|\($)/;

// The mixin-DSL variant: methods declared inside a mixin's `onceAddedClassProperties` hash sit one
// nesting level deeper (4- or 6-space). Indent in m[1], name in m[2].
const MIXIN_METHOD_HEADER = /^( {4,})([A-Za-z_]\w*): (?:(?:\(.*?\)\s*)?[-=]>|\($)/;

// The regression guard for the blind spot itself. A wrapped signature is only visible above because
// it breaks immediately after the `(`; a caller that instead writes
//     foo: (aContext,
//       al, at) ->
// would be invisible again, and — this is the whole lesson — NOTHING would say so, because a gate
// that cannot see a method reports nothing about it. This returns those lines so a gate can FAIL on
// them, turning a silent blind spot into a build error that names its own fix.
// Returns [{ line (1-based), text }]. Two shapes, both anchored at the class-method indent:
//   (a) the line ends in an arrow but we did not match it — a closed header in a spelling we missed;
//   (b) the line OPENS an unbalanced paren list — a wrapped signature whose header line we missed.
// ⚠ (b) tests paren BALANCE, not merely `: (`, so it cannot fire on an option-object key whose value
// is a parenthesised expression (`defaultContents: ((@grow ? 1) * 100).toString()`) — those close on
// the line. An earlier draft of this guard omitted the balance test and flagged nine of them.
function unseenMethodHeaders(lines) {
  const out = [];
  lines.forEach((raw, i) => {
    if (!/^  [A-Za-z_]\w*: \S/.test(raw)) return;         // a class-level key with a value
    if (METHOD_HEADER.test(raw)) return;                  // …that we can already see
    const code = raw.replace(/#.*$/, '');
    let depth = 0;
    for (const ch of code) { if (ch === '(') depth++; else if (ch === ')') depth--; }
    if (/[-=]>\s*$/.test(code) || depth > 0) out.push({ line: i + 1, text: raw.trim() });
  });
  return out;
}

module.exports = { METHOD_HEADER, MIXIN_METHOD_HEADER, unseenMethodHeaders };

// coffee-method-header.js — the ONE spelling of "this line defines a class method", and the ONE
// grouping of a file's lines into methods (class methods and mixin members alike), shared by every
// build gate that groups a `.coffee` file into methods.
//
// WHY THIS EXISTS. Six gates each carried their own copy of
//     /^  ([A-Za-z_]\w*): (\(.*?\) )?[-=]>/
// and every copy had the same blind spot: it requires the `->` on the header LINE, so a method whose
// parameter list WRAPS is not a method header to any of them. `Widget.prompt` and `Widget.textPrompt`
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
// third time: the matcher is now written against the LANGUAGE (`:` then any run of spaces), never
// against a house formatting habit.
//
// WHAT COUNTS AS A HEADER. Either form:
//   1. closed on the line — `foo: ->`, `foo: (a, b) ->`, `foo: (a)->`, `foo: (a) =>`, `foo:  ->`
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
const METHOD_HEADER = /^  ([A-Za-z_]\w*): +(?:(?:\(.*?\)\s*)?[-=]>|\($)/;

// The mixin-DSL variant: methods declared inside a mixin's `onceAddedClassProperties` hash sit one
// nesting level deeper (4- or 6-space). Indent in m[1], name in m[2].
const MIXIN_METHOD_HEADER = /^( {4,})([A-Za-z_]\w*): +(?:(?:\(.*?\)\s*)?[-=]>|\($)/;

// The regression guard for the blind spot itself. A wrapped signature is only visible above because
// it breaks immediately after the `(`; a caller that instead writes
//     foo: (aContext,
//       al, at) ->
// would be invisible again, and — this is the whole lesson — NOTHING would say so, because a gate
// that cannot see a method reports nothing about it. This returns those lines so a gate can FAIL on
// them, turning a silent blind spot into a build error that names its own fix.
// It reads the class-method (2-space) indent only: a mixin member in a spelling MIXIN_METHOD_HEADER
// misses is not reported.
// Returns [{ line (1-based), text }]. Two shapes, both anchored at the class-method indent:
//   (a) the line ends in an arrow but we did not match it — a closed header in a spelling we missed;
//   (b) the line OPENS an unbalanced paren list — a wrapped signature whose header line we missed.
// ⚠ (b) tests paren BALANCE, not merely `: (`, so it cannot fire on an option-object key whose value
// is a parenthesised expression (`defaultContents: ((@grow ? 1) * 100).toString()`) — those close on
// the line. An earlier draft of this guard omitted the balance test and flagged nine of them.
// ⚠ The precondition admits a SPACE before the colon (`name : ->`) precisely so such a line reaches
// the arrow test below and FAILS the gate: that spelling is a third header variation METHOD_HEADER
// does not match, found live on 13 methods by the 2026-08-18 dispatch-slot census — and an earlier
// precondition (`\w*: \S`) skipped those lines entirely, making the guard blind to exactly the bug
// class it exists to catch. The canonical spelling is colon flush against the name.
// ⚠ It also admits a RUN of spaces after the colon (`: +\S`), for the mirror-image reason: the
// earlier `: \S` made the guard blind to the aligned `softWrapOn:  ->` spelling, which METHOD_HEADER
// itself could not see either — nine methods checked by no gate, silently, until 2026-08-24.
function unseenMethodHeaders(lines) {
  const out = [];
  lines.forEach((raw, i) => {
    if (!/^  [A-Za-z_]\w*\s*: +\S/.test(raw)) return;     // a class-level key with a value
    if (METHOD_HEADER.test(raw)) return;                  // …that we can already see
    const code = raw.replace(/#.*$/, '');
    let depth = 0;
    for (const ch of code) { if (ch === '(') depth++; else if (ch === ')') depth--; }
    if (/[-=]>\s*$/.test(code) || depth > 0) out.push({ line: i + 1, text: raw.trim() });
  });
  return out;
}

// THE GROUPING ITSELF, mixin-DSL aware — what a line does to "which method am I in". A mixin
// (src/mixins/*, src/app-kit/*Mixin.coffee) declares its members INSIDE the 2-space
// `onceAddedClassProperties: (fromClass) -> @addInstanceProperties fromClass, { … }` block, one
// nesting level deeper — 4-space (KeepsRatioWhenInVerticalStackMixin) or 6-space (the others) — so
// to a gate that knows only METHOD_HEADER a whole mixin is ONE method named onceAddedClassProperties,
// and every handler a mixin stitches onto a widget is a body that gate never attributes to anyone.
// A gate that cannot see a method reports nothing about it (§6b of lint-and-static-checks.md), so the
// mixin shape lives HERE, once, beside the header spellings it extends.
//   Returns { method, mixinHashIndent, kind: 'header' | 'end' } when the line STARTS or ENDS a
// method, null for a body line. Thread mixinHashIndent through the file: null = not in a mixin
// block; -1 = inside onceAddedClassProperties, awaiting the first member to LOCK the member indent;
// >0 = the locked indent (members at it are headers; deeper headers are defs nested in a member's
// body). For a file with no onceAddedClassProperties it stays null throughout, and the grouping is
// METHOD_HEADER's — except that a 2-space non-method key or a column-0 line ENDS the method
// (kind 'end') instead of being folded into the one above it. Feed it lines whose strings are
// closed where the gate can (check-layering and the two censuses pass the string-stripped line): fed
// RAW lines, a heredoc line at column 0 ends the method it sits in.
const MIXIN_CONTAINER = 'onceAddedClassProperties';
function methodBoundary(raw, mixinHashIndent) {
  const m = raw.match(METHOD_HEADER);
  if (m) return { method: m[1], mixinHashIndent: m[1] === MIXIN_CONTAINER ? -1 : null, kind: 'header' };
  if (mixinHashIndent !== null) {
    const sm = raw.match(MIXIN_METHOD_HEADER);
    if (sm) {
      const indent = sm[1].length;
      const lock = mixinHashIndent === -1 ? indent : mixinHashIndent;
      if (indent === lock) return { method: sm[2], mixinHashIndent: lock, kind: 'header' };
      return null;
    }
  }
  if (/^  [A-Za-z_]\w*:/.test(raw) || /^[^\s]/.test(raw)) return { method: null, mixinHashIndent: null, kind: 'end' };
  return null;
}

// Every method of a file as a span: [{ name, line (0-based header index), end (exclusive), mixin }],
// `mixin` true for a member of a mixin's onceAddedClassProperties block (the container itself is
// reported too, as a 2-space method whose span ends at its first member). The span a gate scans as
// "this method's body" is lines line+1 .. end-1.
function methodSpans(lines) {
  const spans = [];
  let state = null, open = null;
  lines.forEach((raw, i) => {
    const b = methodBoundary(raw, state);
    if (!b) return;
    state = b.mixinHashIndent;
    if (open) { open.end = i; spans.push(open); open = null; }
    if (b.kind === 'header') open = { name: b.method, line: i, end: lines.length, mixin: state !== null && b.method !== MIXIN_CONTAINER };
  });
  if (open) spans.push(open);
  return spans;
}

module.exports = { METHOD_HEADER, MIXIN_METHOD_HEADER, MIXIN_CONTAINER, methodBoundary, methodSpans, unseenMethodHeaders };

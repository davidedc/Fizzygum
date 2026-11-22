'use strict';
// gate-advice.js — what a firing rule's finding MEANS and which answers are right, printed by the gate beside its own
// lines, from one text every gate shares.
//
// A finding means one of three things (docs/architecture/lint-and-static-checks.md §3b): an INVARIANT broken (the
// product is wrong, and the answer is its cause), a CONVENTION held at zero broken (complied with, or the gate's own
// marker with a real reason), or a BUDGET grown — a ratchet above zero, whose new occurrence is classified: the smell
// is fixed, or the right shape raises the number in the same change, its dated reason beside it. ROWS holds each
// rule's own text, keyed by its gate's lib/gate-rules.js name and the rule's id; CLASSES the text a class's rules
// share. A row says what its number holds back (or, first, the question an invariant asks of the new occurrence),
// when a raise is the right answer, and which answers are wrong.
//
// A gate prints the advice after its violation lines, on lines of their own — ONCE PER RULE that fired, however many
// lines it fired on — each rule's row, then each class's shared text once:
//
//   for (const line of adviceLines(rules.gate, ids)) console.error(line);
//
// THE GATE CHOOSES THE IDS, because it knows what a row cannot: a stink is a budget only while its baseline is above
// zero, and one count can be a budget in one repo's half and a convention at zero in the other's.
//
// A row's first line is `[<gate>] ADVICE <RULE_ID> — <head>`. parseAdvice reads those lines back, counted, so a
// bite-proof holds each run to printing the advice of exactly the rules its `advised` names, each once, and each
// class's shared text once (lib/prove-rules.js). An id with no
// row stops the gate (ADVICE_ROW_MISSING, exit 2): its finding would print no advice. A row naming a rule its gate no
// longer has fails lib/gate-advice-selftest.js, which proves the rest.

const { writeAll } = require('./write-all');

const WIDTH = 120;
const INDENT = '    ';

// The text each class's rules share, printed once per run that advised any rule of the class. `gate` is the gate's
// lib/gate-rules.js name.
const CLASSES = {
  C: {
    head: 'A BUDGET (docs/architecture/lint-and-static-checks.md §3b): its number may fall, and rises in the change that needs it.',
    body: [
      'First ask whether the new occurrence is the smell — redundant, misplaced, tangled — and fix it if it is.',
      "A raise is right when the right shape needs it (a named helper, a public door, an intent-named notification, the natural home); when a refactor one ratchet exists to drive crosses another (a split adds methods to a class at its ceiling); when the gate's measurement widened; when an instruction file's sentence must grow to stay true.",
      'Never: a helper that deserves its name inlined, two concepts folded into one, an odd home, a trade made only for the count, a wording chosen by its length, a true fact dropped.',
      'To raise: in the same change, the dated reason beside the number (`raised N -> M on YYYY-MM-DD: <the member, and the one question it answers>`), or in the commit message where the number lives in a file that holds no comment; the commit message names the ratchet.',
    ],
  },
};

// Each rule's own text: { class, head, body }. `head` stands on the ADVICE line — what the number holds back, or the
// question to answer first; `body` follows it.
const ROWS = {
  'check-complexity-ratchets': {
    METHOD_COUNT_ABOVE_CEILING: { class: 'C',
      head: 'METHOD_CEILINGS holds back a class growing by members whose home nobody asked about.',
      body: "Is the new member redundant, or does its behaviour belong to another class? Then fix that. A member that deserves its name and whose natural home is this class (a named helper, a public door, an intent-named notification, a long method split into its phases) raises the class's ceiling. A member inlined, folded into another or moved to an odd home only to hold the count is the wrong answer." },
    COMPLEXITY_ABOVE_CEILING: { class: 'C',
      head: 'COMPLEXITY_CEILING holds back functions nobody can read whole.',
      body: 'Split it along a real seam. It is RECORDED, its dated reason beside the entry, when it is born of a split that lowers a recorded parent, or when no real seam remains: state threaded through many-parameter helpers, or a cut across a try/finally, is no seam. A cut along no seam, made only to bring the score under the ceiling, is the wrong answer.' },
    COMPLEXITY_ABOVE_RECORD: { class: 'C',
      head: 'RECORDED holds back a recorded tangle growing further.',
      body: 'Split it along a real seam, which lowers the record. When the line the right shape adds has no seam to go to, the record rises, its dated reason beside it. A needed line left out, or squeezed into a denser expression to hold the score, is the wrong answer.' },
  },
  'check-stinks': {
    'null-literal': { class: 'C',
      head: 'the baseline holds back `null` where the code chooses its absence value: `undefined` is the one absence value.',
      body: "Spell it `undefined`. A site a foreign API makes `null` (the DOM's reset value, Object.create's argument for an object with no prototype) is named in this stink's `sanctioned` list with its why, where it cannot absorb the next site; the baseline rises only for one more of the tolerated tail, when the right shape needs it. A `null` hidden from the pattern (built, or read from a string) is the wrong answer." },
    'clock-read': { class: 'C',
      head: "first: does this read reach render, layout or input? Then it is a determinism bug whatever the count (Fizzygum-tests/DETERMINISM.md): read the cycle's time (WorldWdgt.dateOfCurrentCycleStart) or the event's timestamp.",
      body: "Only then the budget, which holds back clock reads no test frame can depend on: a read no test frame waits on (the harness's DOM overlay, a compile budget, a debug log) is named in this stink's `sanctioned` list with its why, where it cannot absorb the next site; the baseline rises only for one more of the tolerated tail, when the right shape needs it. A clock read through a spelling the pattern misses is the wrong answer." },
    timer: { class: 'C',
      head: 'first: does it reach render, layout or input? Then it is a determinism bug whatever the count (Fizzygum-tests/DETERMINISM.md bug-class B: heavy cycles starve timers): step it from the world cycle.',
      body: "Only then the budget, which holds back real-time callbacks beside the world cycle: a timer no world frame waits on (a boot pump that runs while no world exists, a download's clean-up) raises the baseline, its dated reason in the trailing comment. A timer behind a spelling the pattern misses is the wrong answer." },
    'math-random': { class: 'C',
      head: 'first: does the value reach render, layout or input? Then it breaks byte-exact screenshots whatever the count: derive it from state.',
      body: "Only then the budget, which holds back randomness in framework code: a value no test frame shows (the debug damage overlay's colours) raises the baseline, its dated reason in the trailing comment. A random source the pattern misses is the wrong answer." },
    'instanceof-type-test': { class: 'C',
      head: 'the baseline holds back type tests where behaviour or a capability belongs (docs/architecture/widget-authoring-guidelines.md §14).',
      body: "Move the behaviour, or ask a query named for the CAPABILITY; a type-named predicate (isScrollPanel) is the same test under another name, and the wrong answer. An honest type test (an exception's class, a class judged before any instance of it exists) is named in this stink's `sanctioned` list with its why, where it cannot absorb the next site; the baseline rises only for one more of the tolerated tail (a reflective walker over host objects, which no polymorphism reaches), when the right shape needs it." },
    'comment-narration': { class: 'C',
      head: 'the baseline holds back comments that tell history: a comment states what IS.',
      body: 'State what the code does and why; the history goes to docs/archive/. A warning that must name what it bans is restated as a present-tense constraint ("never X, because Y"); the baseline rises only when no present-tense wording keeps the warning true, its dated reason in the trailing comment. A true warning deleted to go quiet, or reworded around the pattern, is the wrong answer.' },
  },
  'check-call-separation': {
    U_QUERY_SELF_ONLY: { class: 'C',
      head: 'BASELINE_U_QUERY holds back public queries nothing outside their class asks: a tier claiming an API the code does not have.',
      body: 'Re-tier it `_` when its role is internal (node ./buildSystem/census-public-private-calls.js --full lists every candidate); deliberate end-user API (the in-world inspector, scripting) goes in buildSystem/public-api-allowlist.txt with its reason; the baseline rises when the census\'s measurement widened. A reference added only to take a query out of the count is the wrong answer.' },
  },
  'check-plane-discipline': {
    B_MIX_ROSE: { class: 'C',
      head: 'first: are both receivers in one plane BY CONSTRUCTION (a container laying out its own children, siblings under one parent)? If either can sit in another plane (a scrolled pane, a transform island), the line is a bug dormant at offset 0: map it (localPointToScreen, screenPointToMyPlane, screenBounds).',
      body: 'Only then the budget, which holds back positional lines whose plane nobody has classified: a line in one plane by construction raises CROSS_PLANE_MIX_BASELINE, its dated reason in the comment above it naming the shared parent. A mapping call added to a same-plane line only to take it out of the count is the wrong answer.' },
  },
  'check-hand-lists': {
    OVER_BASELINE: { class: 'C',
      head: 'the baseline holds back second sources of truth: a list mirroring names declared elsewhere checks less the day they move.',
      body: "Derive it from the declaration it mirrors; a check's EXPECTED list is asserted literally, both ways, and sanctioned naming the guard that fails (derived from the rule it judges, a check agrees with itself). The baseline rises only when the gate's measurement widened. A clear list replaced by reflection, or a literal reshaped so the detector misses it, is the wrong answer." },
  },
  'census-widget-conformance': {
    PROLOGUE_COPY: { class: 'C',
      head: 'BASELINE_PROLOGUE_COPIES holds back hand-copied _reLayout prologues drifting from Widget._reLayoutWithOwnContents.',
      body: 'Take the template. A genuinely different shape raises the baseline, named beside it with the others it lists and dated. A prologue respelled so the census misses it is the wrong answer.' },
  },
  'check-doc-narration': {
    INSTRUCTION_FILE_OVER_CEILING: { class: 'C',
      head: 'instructionBytes holds back the bytes every session pays before any work, and again after every compaction.',
      body: "Mechanism, history, measurements and case law move to the rig's header or the architecture doc that owns them. A rule every reader must meet, or a sentence that must grow to stay true, raises the ceiling: `--write-baseline`, which re-records every number of the baseline file, or that one number edited by hand. The file holds no comment, so the reason goes in the commit message. A sentence shortened until it is false is the wrong answer." },
  },
};

// `text` broken into lines of at most WIDTH characters at spaces: the first starting with `first`, the rest with INDENT
function wrap(text, first) {
  const out = [];
  let line = first;
  for (const word of text.split(' ')) {
    if (line.length + word.length + 1 > WIDTH && line.trim() && line !== first) { out.push(line); line = INDENT; }
    line += (line === first || line === INDENT ? '' : ' ') + word;
  }
  out.push(line);
  return out;
}

// The lines a gate prints for the rules `ids` (each once, in the order given): each rule's row, then the shared text
// of each class among them, once. No id, no line. An id with no row stops the gate: exit 2, ADVICE_ROW_MISSING.
function adviceLines(gate, ids) {
  const own = ROWS[gate] || {};
  const seen = [...new Set(ids)];
  const missing = seen.filter((id) => !Object.prototype.hasOwnProperty.call(own, id));
  if (missing.length) {
    writeAll(2, `[${gate}] ADVICE_ROW_MISSING ${missing.join(' ')} — lib/gate-advice.js holds no row for it: write the row (what its number holds back, when a raise is the answer, the wrong answers), or print no advice for it\n`);
    process.exit(2);
  }
  const lines = [];
  const classes = [];
  for (const id of seen) {
    const row = own[id];
    lines.push(...wrap(row.head, `[${gate}] ADVICE ${id} — `), ...wrap(row.body, INDENT));
    if (!classes.includes(row.class)) classes.push(row.class);
  }
  for (const c of classes) {
    lines.push(...wrap(CLASSES[c].head, `[${gate}] `));
    for (const paragraph of CLASSES[c].body) lines.push(...wrap(paragraph, INDENT));
  }
  return lines;
}

const ADVICE_LINE_RE = /^\[([\w.-]+)\] ADVICE ([A-Za-z0-9][\w.-]*) — /gm;

// What `out` holds of the advice of the gate named `gate`: a Map from each rule id whose ADVICE header it prints to
// the number of times it prints it. A class's shared text is owed exactly once by a run that prints a row of that
// class, and never otherwise; printed any other number of times it enters the Map too, as `<class>-shared-text` → that
// number. So advice printed right reads as its rule ids, each once, and a judge holding the Map to that sees a header
// or a shared text doubled, or missing. Another gate's advice (one gate run inside another prints both) is not this
// gate's.
function parseAdvice(out, gate) {
  const text = String(out || '');
  const counts = new Map();
  for (const m of text.matchAll(new RegExp(ADVICE_LINE_RE.source, 'gm'))) {
    if (m[1] === gate) counts.set(m[2], (counts.get(m[2]) || 0) + 1);
  }
  const rows = ROWS[gate] || {};
  const lines = text.split('\n');
  for (const [c, shared] of Object.entries(CLASSES)) {
    const opening = wrap(shared.head, `[${gate}] `)[0];
    const printed = lines.filter((l) => l === opening).length;
    const owed = [...counts.keys()].some((id) => Object.prototype.hasOwnProperty.call(rows, id) && rows[id].class === c) ? 1 : 0;
    if (printed !== owed) counts.set(`${c}-shared-text`, printed);
  }
  return counts;
}

module.exports = { adviceLines, parseAdvice, ADVICE_LINE_RE, ROWS, CLASSES };

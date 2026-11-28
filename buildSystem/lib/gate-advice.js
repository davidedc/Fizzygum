'use strict';
// gate-advice.js — what a firing rule's finding MEANS and which answers are right, printed by the gate beside its own
// lines, from one text every gate shares.
//
// A finding means one of three things (docs/architecture/lint-and-static-checks.md §3b): an INVARIANT broken (the
// product is wrong, and the answer is its cause), a CONVENTION held at zero broken (complied with, or the gate's own
// marker with a real reason), or a BUDGET grown — a ratchet above zero, whose new occurrence is classified: the smell
// is fixed, or the right shape raises the number in the same change, its dated reason beside it. ROWS holds each
// rule's own text, keyed by its gate's lib/gate-rules.js name and the rule's id; CLASSES the text a class's rules
// share. An invariant's or a convention's row names its QUIET FIXES — the answers that silence the line and keep
// what it found — as wrong, says why, and gives the right answer; where the rule keeps a marker, what the marker
// answers and what its reason names. A budget's row says what its number holds back (or, first, the question an
// invariant asks of the new occurrence), when a raise is the right answer, and which answers are wrong.
//
// ONE ROW SERVES SEVERAL RULES of its gate whose findings share one answer: its key names them, separated by spaces
// ('READS_BEFORE_APPLY HOOK_WITHOUT_TEMPLATE'), and it prints once however many of them fired, its header naming the
// ones that did. An id is a rule id, or a rule id qualified by the case it fired in (`OVER_BASELINE.at-zero`) where
// one rule's finding means different things by case; a rule id holds no `.`.
//
// A gate whose rules come from a list it does not keep gives them ONE row keyed `*`: it serves every id the gate asks
// for that no other row of the gate names. The suite runner's gate tokens are the case — Fizzygum-tests/scripts/lib/
// gate-tokens.js holds them, and a second list of them here would rot the day a token is added — so such a gate passes
// the ids its `*` row serves itself, beside what advisedAmong keeps (the ids a row names).
//
// A gate prints the advice after its whole report, on lines of their own — ONCE PER ROW, however many lines its rules
// fired on — each row, then each class's shared text once:
//
//   const advised = advisedAmong(rules.gate, rules.firedIds);   // the fired rules that carry a row
//   if (advised.length) { console.error(''); for (const l of adviceLines(rules.gate, advised)) console.error(l); }
//
// A rule with no row prints no advice: its own line gives its one answer (every stale-entry rule's "delete the
// entry"), or its gate carries no rows (docs/architecture/lint-and-static-checks.md §3b says which do). Where the case decides the row, THE GATE CHOOSES THE IDS, because it knows what a row cannot: one count can
// be a budget in one repo's half and a convention at zero in the other's. A stink's row is written for its baseline:
// a stink tightened to zero is a convention, and its row is rewritten with it (lib/gate-advice-selftest.js fails a
// check-stinks row whose class disagrees with its stink's live baseline).
//
// A row's first line is `[<gate>] ADVICE <ids> — <head>`. parseAdvice reads those lines back, counted, so a bite-proof
// holds each run to printing the advice of exactly the rules its `advised` names, each once, each row once, and each
// class's shared text once (lib/prove-rules.js). An id asked for with no row stops the gate (ADVICE_ROW_MISSING, exit
// 2): its finding would print no advice. A row naming a rule its gate no longer has fails lib/gate-advice-selftest.js,
// which proves the rest.

const { writeAll } = require('./write-all');

const WIDTH = 120;
const INDENT = '    ';
// the key of the row that serves every id no other row of its gate names
const ANY = '*';

// The text each class's rules share, printed once per run that advised any rule of the class. `gate` is the gate's
// lib/gate-rules.js name.
const CLASSES = {
  A: {
    head: 'AN INVARIANT (docs/architecture/lint-and-static-checks.md §3b): a finding is the product being wrong, answered at its cause, outside the narrow case its own row names.',
    body: [
      'Fix the cause; when the cause cannot be fixed in scope, stop and report.',
      'Never, for a real finding: a new exemption or allowlist entry, a suppression flag, a stub, a guard at the one leaf that threw, a recapture that banks the wrong picture. Each hides the bug, which is worse than a bent shape.',
      "A table entry or a marker is right only in the narrow case its rule's row names — a vendor API, a test oracle, a throw that IS the row's behaviour, a flow the scan cannot tell from a broken one — and its reason names that case; it never keeps a real finding.",
    ],
  },
  B: {
    head: 'A CONVENTION AT ZERO (docs/architecture/lint-and-static-checks.md §3b): a house rule is broken, and the code may still run.',
    body: [
      "Comply, or write the gate's own marker with a reason a reviewer can check.",
      'Never: a design bent to avoid writing the marker, a marker with a boilerplate reason, a spelling chosen so the scan misses the line.',
    ],
  },
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

// Each row's own text: { class, head, body }. `head` stands on the ADVICE line — what the finding means, what the
// number holds back, or the question to answer first; `body` follows it.

// the row every retired-mechanism gate shares: each gate's own lines name the mechanism's replacement
const RETIRED_MECHANISM = { class: 'B',
  head: 'a retired mechanism brought back.',
  body: 'Quiet fixes: the same mechanism respelled so this scan misses it — a marker syntax of its own, a renamed verb, a name built at run time — or a tolerance written for it (a baseline above zero, an exempt path). Right: its replacement, which the lines above name; for an exclusion, the code re-homed — promoted when it is product, a `*TestSupport` class when it is test machinery, a guarded collaborator or a part otherwise — and never a new marker syntax.' };

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
    'debugger-statement': { class: 'A',
      head: 'a stop only devtools see: a branch that detects a broken invariant reports it where every run sees it.',
      body: 'Quiet fixes: a raise of the baseline; the statement spelled so the pattern misses it. Right: report the broken invariant under a gate token (`console.error "INVARIANT_VIOLATED: …"`, which the headless runners fail on), or delete the stop.' },
    'nil-literal': { class: 'A',
      head: '`nil` is a ReferenceError: the `nil = undefined` global is retired.',
      body: 'Quiet fix: a raise of the baseline, which tolerates a name that throws. Right: spell it `undefined`, the one absence value.' },
    'raw-chrome-color': { class: 'B',
      head: 'a chrome look decided outside Theme: a restyle edits src/Theme.coffee and cannot reach it (docs/architecture/visual-design-system.md).',
      body: "Quiet fixes: a raise; an `exclude` prefix over a chrome file; a `sanctioned` entry for a literal that IS a look decision; a colour spelled so the pattern misses it. Right: read the surface's role (`WorldWdgt.theme.<role>`), adding a role when the surface has none; a literal that is data (a wallpaper design's own colours, palette content, the value a prompt opens at) is named in `sanctioned` with its why." },
    'comment-meta-edit commented-out-debug comment-past-receipt': { class: 'B',
      head: 'a comment that argues with itself, keeps dead debug, or narrates a conversion: a comment states what IS.',
      body: 'Quiet fixes: a raise; a rewording that slips past the pattern while the comment still argues or narrates. Right: state the surviving constraint once, plainly; delete commented-out debug (git remembers); translate a `was <old code>` receipt into the present-tense contract it documents, and let docs/archive/ keep the before-picture.' },
    SANCTION_COUNT: { class: 'B',
      head: 'a sanctioned member holding a different number of hits than its entry declares.',
      body: "Quiet fix: the count set to the number found, which sanctions a literal nobody read. Right: read each hit in the member: a new one that is the smell is fixed, one that is not stays, and the count then says how many are not the smell." },
  },
  'check-call-separation': {
    'S_SETTLING_SELF_CALL S_EFFECTFUL_SELF_CALL': { class: 'B',
      head: 'a private method self-calling a public command: a second flush ([S] settling), or a public door used as an internal step.',
      body: 'Quiet fixes: either member re-tiered only so the line goes quiet; `# public-call-sanctioned:` with a reason that names no command it reuses; a raise of the baseline. Right: a tier states the member\'s role — when the callee\'s role is internal, re-tier it `_`, or call its `_<name>NoSettle` core; when the private method genuinely reuses a public command, mark the CALLER `# public-call-sanctioned: <which command it reuses, and why its core does not serve>`.' },
    U_EFFECTFUL_SELF_ONLY: { class: 'B',
      head: 'a public command only its own class calls: a tier claiming an API the code does not have.',
      body: 'Quiet fixes: an entry in buildSystem/public-api-allowlist.txt calling an internal method end-user API because a layering rule refuses its `_` form; a reference from outside written only to take it out of the count. Right: a method only its own class calls takes the `_` form; where [A] or [G] then refuses a settling call it makes, it reaches its OWN non-settling core first (`_<name>NoSettle`, or a part\'s it built and holds, inside one settle), and only a call into ANOTHER object at event time, whose own settle is the point, carries `# settling-call-sanctioned:` on its line; where [S] refuses one, the method carries `# public-call-sanctioned:`; each with its reason. The allowlist holds what a person calls from the in-world inspector or a script, each entry naming that surface.' },
    U_QUERY_SELF_ONLY: { class: 'C',
      head: 'BASELINE_U_QUERY holds back public queries nothing outside their class asks: a tier claiming an API the code does not have.',
      body: 'Re-tier it `_` when its role is internal (node ./buildSystem/census-public-private-calls.js --full lists every candidate); deliberate end-user API (the in-world inspector, scripting) goes in buildSystem/public-api-allowlist.txt with its reason; the baseline rises when the census\'s measurement widened. A reference added only to take a query out of the count is the wrong answer.' },
  },
  'check-plane-discipline': {
    B_MIX_ROSE: { class: 'C',
      head: 'first: are both receivers in one plane BY CONSTRUCTION (a container laying out its own children, siblings under one parent)? If either can sit in another plane (a scrolled pane, a transform island), the line is a bug dormant at offset 0: map it (localPointToScreen, screenPointToMyPlane, screenBounds).',
      body: 'Only then the budget, which holds back positional lines whose plane nobody has classified: a line in one plane by construction raises CROSS_PLANE_MIX_BASELINE, its dated reason in the comment above it naming the shared parent. A mapping call added to a same-plane line only to take it out of the count is the wrong answer.' },
    A_BARE_OFFSET_WRITE: { class: 'A',
      head: 'a scroll offset written outside `_writeScrollOffset`, the one funnel every offset write goes through.',
      body: 'Quiet fix: the write spelled so this pattern misses it. Right: call `_writeScrollOffset`.' },
    'C1_ESCALATED_POS C2_RAW_SCREEN_POS': { class: 'A',
      head: "a pointer position read in a plane that is not the receiver's: right at offset 0, wrong once scrolled or tilted.",
      body: "Quiet fixes: the read moved into a helper the handler calls, whose body this scan does not read; a position mapped as if it came from the screen when it is already in another plane (an escalated `pos` is in a descendant's plane); `# escalated-pos-sanctioned:` on a handler that can re-derive. Right: as the line says — an escalated `pos` is re-derived from the hand (`@screenPointToMyPlane world.hand.position()`), a raw screen `pos` is mapped on the line that reads it. The marker, above the handler, answers a provider that consumes a descendant-plane position on purpose, and its reason names what reads it in that plane." },
  },
  'check-hand-lists': {
    OVER_BASELINE: { class: 'C',
      head: 'the baseline holds back second sources of truth: a list mirroring names declared elsewhere checks less the day they move.',
      body: "Derive it from the declaration it mirrors; a check's EXPECTED list is asserted literally, both ways, and sanctioned naming the guard that fails (derived from the rule it judges, a check agrees with itself). The baseline rises only when the gate's measurement widened. A clear list replaced by reflection, or a literal reshaped so the detector misses it, is the wrong answer." },
    // a half held at zero is a convention: a list over it (OVER_BASELINE.at-zero) is answered as an unsanctioned list
    // in --files mode is, and as a sanction naming no guard that runs
    'OVER_BASELINE.at-zero UNSANCTIONED_NAME_LIST SANCTION_NAMES_NO_GUARD SANCTION_GUARD_NEVER_RUNS': { class: 'B',
      head: 'a name list neither derived nor asserted, or a sanction naming no guard that runs: a second source of truth, which checks less the day its names move.',
      body: "Quiet fixes: the literal reshaped so the detector misses it (an object keyed by the names, a regex, a run of `&&`, a list padded with data words); a sanction naming a guard that runs but does not cover this list. Right: derive the list where code reads a declaration; otherwise assert it both ways against what is declared, and sanction it naming the guard that fails when THIS list goes stale — when none does, write that assertion first. In a check — a rig, a gate, a test — a list that is the EXPECTED value stays a literal: derived from the product rule the check judges, the expectation shrinks with the bug." },
  },
  'census-widget-conformance': {
    PROLOGUE_COPY: { class: 'C',
      head: 'BASELINE_PROLOGUE_COPIES holds back hand-copied _reLayout prologues drifting from Widget._reLayoutWithOwnContents.',
      body: 'Take the template. A genuinely different shape raises the baseline, named beside it with the others it lists and dated. A prologue respelled so the census misses it is the wrong answer.' },
    UNDECLARED_FIELD: { class: 'A',
      head: 'a field written but never declared: invisible to a copy, a save and the inspector until the method that writes it has run.',
      body: 'Quiet fix: the write spelled so this census does not read it as a field, which keeps the field and hides it. Right: declare it at class level (`name: undefined`).' },
  },
  'check-doc-narration': {
    INSTRUCTION_FILE_OVER_CEILING: { class: 'C',
      head: 'instructionBytes holds back the bytes every session pays before any work, and again after every compaction.',
      body: "Mechanism, history, measurements and case law move to the rig's header or the architecture doc that owns them. A rule every reader must meet, or a sentence that must grow to stay true, raises the ceiling: `--write-baseline`, which re-records every number of the baseline file, or that one number edited by hand. The file holds no comment, so the reason goes in the commit message. A sentence shortened until it is false is the wrong answer." },
    'USED_TO LONG_SAID WAS_REWORDED PAST_TENSE_CHANGE FORMERLY SINCE_PARTICIPLE EXECUTED_DATE VERB_DATE UNTIL_SINCE_DATE IN_MONTH_YEAR THE_THEN_OLD_THING': { class: 'B',
      head: 'history told in a present-tense doc (docs/README.md filing rule 3): a reader takes it for the current fact.',
      body: 'Quiet fixes: `--write-baseline`, which records the new narration as tolerated; a warning that names a retired shape deleted; a rewording that only slips past the pattern; `narration-ok` on a line that quotes nothing. Right: restate the line as the present-tense fact or constraint ("never X, because Y"), and move the history to the plan or archive doc that owns it. `<!-- narration-ok: <reason> -->` on a line answers one that must QUOTE the trigger words (a table of the patterns).' },
  },
  'run-selftests': {
    'SELFTEST_FAILED SELFTEST_NO_VERDICT SELFTEST_VACUOUS': { class: 'A',
      head: 'a proof that broke: the checker it proves gives no verdict worth reading until the proof holds again.',
      body: "Quiet fixes: a case's regex or expectation loosened until it matches what prints; a case deleted; the new output recorded as the expectation without reading why it changed. Right: read the case's failure line, then fix whichever is wrong — the checker, or the case, which then says what IS true and can still fail." },
    'SELFTEST_OUTSIDE_CONVENTION SELFTEST_UNDISCOVERED': { class: 'A',
      head: 'a self-test nothing runs: it proves nothing, and its checker can be wrong on every build in between.',
      body: "Quiet fix: a name or a switch spelled so neither scan sees it. Right: a `<subject>-selftest.js` (or `-selftest-headless.js`) file among the tooling's own files (lib/what-runs.js scriptFiles), found and run by name; a self-test switch in a script's code goes, its cases moving into that file." },
    'GATE_WITHOUT_REGISTRY GATE_WITHOUT_PROOF': { class: 'A',
      head: 'a launched gate no proof holds: its verdicts come from a checker nobody has seen fail.',
      body: "Quiet fixes: a `not-a-gate:` header on a script that judges (it exits non-zero on a finding); a `bite-unplantable:` line for a rule a plant can reach; a plant that prints a rule's line where the drift the rule names can be made. Right: name its rules through lib/gate-rules.js (`require(…gate-rules…).forGate(__filename)`) and give it a self-test that launches it by `path.join(__dirname, …)` through proveGate or proveLeg, planting each rule's real drift. `// not-a-gate: <reason>` (`#` in a shell or Python file) heads a script that judges nothing — a build step, a runner — and its reason says what it does instead." },
  },
  'check-coffee-syntax': {
    'PARSE_ERROR LOST_HELPER': { class: 'A',
      head: "a source that does not compile the browser's way: the page throws compiling it, or where the member runs.",
      body: 'Quiet fix: `--noSyntaxCheck`, which skips every gate, ships the source unchecked and moves the error to the page. Right: fix the source — a parse error at the line named (a member compiles as its own fragment); a lost helper by rewriting the construct the compiler declares it for, as the line says.' },
  },
  'check-shippable-coverage': {
    UNSHIPPED: { class: 'A',
      head: 'a source no part ships: `<Class> is not defined` where it runs, and nothing else says so.',
      body: 'Quiet fix: the directory claimed in whichever part makes the gate pass (core, or the first part at hand), which ships it where it does not belong or loads it before what it needs. Right: claim it in the part that owns it — the part whose classes it serves, core only for what core cannot run without — and a src/boot file in the bootPrelude or bootScripts of the part it boots for.' },
    'BOOT_FETCH_UNDECLARED BOOT_SCRIPT_UNFETCHED': { class: 'A',
      head: "boot fetches a script by a name its part's bootScripts does not declare: a 404 at every boot.",
      body: "Quiet fix: the fetched name built at run time, which this scan reads as no fetch. Right: name the script in its own part's bootScripts and fetch it as a literal `js/src/<name>-min.js` in code; a rename changes both sides." },
  },
  'check-layering': {
    'A_PUBLIC_SETTER A_TEXT_SETTER A_RECALC C_SETTER_CALLS_SETTER G_SETTLING_WRAPPER G_SELF_ADD T_DOUBLE_SETTLE': { class: 'A',
      head: 'a second settle reached where the one flush cannot survive it — [A] [G] low-level code calling a self-settling method, [C] a public setter calling another, [T] a self-settling method calling a settling one.',
      body: 'Quiet fixes: a member renamed so a name-keyed rule stops judging it (`_x` to `x`, the caller out of the low-level tier); a helper folded into its public caller so no low-level method makes the call; a marker on a call that does reach a second settle. Right: reach your OWN non-settling core first (`_<name>NoSettle`, `@_addNoSettle`, `_setTextNoSettle`, or the core of a part you built and hold) inside the one settle; a name states the member\'s role, so rename only when the role is wrong (docs/architecture/lint-and-static-checks.md §4). Only then, for a call into ANOTHER object reached where no settle or pass is open — at event time, from a press\'s hook, a catch path, the cycle\'s own reconciler — whose own settle is the point, or on a receiver of a plain class (the line\'s NB names it): `# settling-call-sanctioned:` [A] [G], on the call\'s line, each call it excuses counted (AG_MARKER_COUNT_ABOVE_CEILING); its reason names the door that reaches the method and whose settle the call is. `# double-settle-sanctioned:` [T] answers a deliberate sequential pair or a branch-exclusive one, and its reason says which. [A]\'s recalculateLayouts and [C] keep no marker.' },
    AG_MARKER_COUNT_ABOVE_CEILING: { class: 'C',
      head: 'SETTLING_CALL_MARKER_CEILING is a tripwire: each marked call is a settle [A] and [G] take on its reason\'s word, and a new one arrives only as a dated line in the gate.',
      body: "First ask whether the call reaches a core of the caller's own, or of a part it built and holds, inside one settle: then it takes no marker. A sound new call (reached where no settle or pass is open, its reason naming the door) raises the number in the same change, its dated reason naming the member and the door; that raise is the expected answer, and the record a reader reads. Two calls merged into one, or a call moved into a public helper this scan does not judge, to hold the number, is the wrong answer; so is a foreign `_<name>NoSettle` core called to avoid the marker." },
    'B_RECALC_CALLER O_DEFERRED_SETTLE_CALLER P_JOIN_LANE_CALLER Q_CONNECTOR_CALLER': { class: 'A',
      head: 'a flush lane entered by a caller it is not sound for — [B] recalculateLayouts(), [O] a *DeferredSettle entrypoint, [P] the join lane, [Q] a _<name>Connector entrypoint.',
      body: "Quiet fixes: an allowlist entry for a caller that is not what its table holds (a discrete or programmatic caller in DEFERRED_SETTLE_CALLER_ALLOWLIST, a caller that forces no ground truth in RECALC_ORACLES); a method renamed `_<name>Connector` to enter the join lane. Right: the self-settling setter, or `_settleLayoutsAfter` around a `_<name>NoSettle` core. A table entry names a caller that is what its table holds — a per-event stream handler that never reads the settled layout mid-cycle, a mid-cascade self-render, an oracle forcing the ground truth — and nothing else." },
    'E_MUTATOR_INVALIDATES E_MUTATOR_VALVE F_OFF_SETTLE_APPLY I_LEAF_ORCHESTRATES J_HOOK_SETTLES K_TWIN_SEAM K_TWIN_DISPATCH K_COMMIT_REACTS': { class: 'A',
      head: 'a tier doing what its name says it never does — [E] an immediate mutator scheduling layout, [F] a handler applying a container refit off the settle, [I] a __ leaf orchestrating, [J] a notification hook opening a settle, [K] a 2x2 apply corner doing what its corner does not.',
      body: 'Quiet fixes: the method renamed into another tier, or out of every pattern, so another rule judges it or none does (a callback renamed out of `_reactTo*`/`_before*`); the call moved into a helper the scan judges differently; the [F] marker on an apply that can defer. Right: the call moves to the tier that owns it — a mutator only mutates, a handler defers (`_invalidateLayout`), the dispatcher owns the one `_settleLayoutsAfter`, a leaf stays a pure bottom, a corner matches its name (the layering/naming convention §1–§3). `# layout-apply-sanctioned:` [F] answers an apply at a settle point or in a documented determinism-exempt family (scroll input, collapse, construction), and its reason names which.' },
    D_MACRO_PRIVATE_CALL: { class: 'B',
      head: 'a macro calling a private or low-level method: a test that drives the world where a person cannot, or reads what no person sees.',
      body: "Quiet fixes: a private member made public product API, or given a public twin, so a macro can call it; a call that drives the world moved into a toolkit method, where this rule does not look. Right: a macro drives the world through input and reads it through the public queries a person or a script would want (for measure-and-size: attach the widget, then setExtent/setWidth/moveTo); a toolkit method locates or reads by meaning, and never drives the world past the input queue. `# macro-private-call-sanctioned: <what it reads, and why no public query answers it>` answers a test ORACLE that must read ground truth (`world._fullChanged()`)." },
    'L_CALLBACK_NOSETTLE L_MALFORMED_CALLBACK L_LEGACY_CALLBACK_FRAGMENT M_RETIRED_FRAGMENT M_RETIRED_ANDNOTIFY N_RETIRED_SEAM_VERB': { class: 'B',
      head: 'a name outside the tier scheme — [L] a notification callback not named `_(reactTo|before)(Being|Child|HolderFrame)<Event>`, or carrying NoSettle; [M] a retired fragment (raw*/silent*/fullRaw, `_apply*AndNotify`); [N] the retired `_announce*ToContainer` seam.',
      body: 'Quiet fixes: a spelling that slips past the pattern and keeps the retired meaning (a container notified by mutation under a new verb); a callback renamed out of the scheme, where the settle audit, which wraps callbacks by name, no longer sees it. Right: the scheme\'s name — `_apply*`/`_apply*Base`/`_commit*`/`__` tiers (raw pixel data is `rawPixel*`/`rawRGBA`), a callback named `_reactTo…`/`_before…` with no NoSettle — and a container re-fits through the settle-time up-edge `_reFitMyTrackingContainerAfterSettle` (the layering/naming convention §3, §4).' },
    R_USERLAND_PRIVATE: { class: 'B',
      head: "the userland exemplar reaching into another widget's private core: the menu-built windows are the example user code copies.",
      body: 'Quiet fix: the private core made public so the exemplar can call it. Right: the public self-settling API a person\'s code uses (setBounds, moveTo, setExtent, setWidth, setHeight, moveWithin). `# private-use-sanctioned: <reason>` on the line answers a reach the public API cannot make, and its reason names what the API lacks.' },
  },
  'check-invalidation-receivers': {
    CROSS_INVALIDATION: { class: 'A',
      head: "a widget marking another changed: the receiver's damage decided outside it (docs/architecture/widget-citizenship.md, point 2).",
      body: 'Quiet fixes: `# cross-invalidation-sanctioned:` with a reason that names no plumbing ("needed here", "to repaint"); a general-purpose public repaint verb on the receiver, for its callers to call. Right: the receiver marks itself changed inside the method invoked on it — its own mutation method, or an intent-named public one (`world.noteWallpaperChanged`, `world.caret.noteTextChanged`); a mark the structural dispatcher already makes is deleted. The marker answers plumbing this scan cannot tell from reaching over — a structural mover, the world\'s overlay reconcilers, an async asset\'s repaint, an own sub-part\'s non-invalidating tier — and its reason names which.' },
  },
  'check-dead-methods': {
    DEAD_METHOD: { class: 'B',
      head: 'a member nothing reaches — by property access, whole-name string, name template or computed class access (lib/method-references.js).',
      body: 'Quiet fixes: an entry that reads "intentional API, currently unused", or `--update-allowlist`, which re-seeds the allowlist with every dead method; a call written in a rig or a test only so the method counts as reached. Right: delete it — a menu action or a pin setter named by a string already counts as reached, so nothing reaches this one; a product member whose only caller is a check is a finding, and the check asks the member the product uses. An entry in buildSystem/dead-method-allowlist.txt answers a reach this scan cannot see, and its reason names that reach: the devtools console, a name assembled with `+`, the arbitrary object it is dispatched through (`@target[action]`).' },
  },
  'check-unresolved-sends': {
    UNRESOLVED_SEND: { class: 'A',
      head: 'a send nothing answers: a TypeError on any path that reaches it — or a platform method this gate does not know.',
      body: "When Fizzygum should answer it, the quiet fixes are a stub or a `-> false` default on Widget; a soaked call (`x.name?()`) of a name nothing defines, which this gate does not read and which then does nothing, always; an allowlist entry, or `--update-allowlist`, which re-seeds the allowlist with every unresolved send. Right: implement it on the class that answers it, or drop the call (a capability query lives on the class that answers it, never defaulted on Widget: docs/architecture/widget-authoring-guidelines.md §14). When it is a platform method, the quiet fix is a correct call respelled (`startsWith` as a regex, `Object.is` as arithmetic) until the gate stops matching. Right: add it to the BUILTINS of check-unresolved-sends.js — bare, or keyed `Recv.name` when Fizzygum also defines the name — and keep the plain call. buildSystem/unresolved-sends-allowlist.txt holds a vendor or host API, or a genuinely dynamic send, each with what provides it." },
  },
  'check-call-arguments': {
    HOLE: { class: 'A',
      head: 'a call passing `undefined` only to reach a later argument, which its witness does not pass: the parameter list is wrong (docs/architecture/constructor-and-parameter-conventions.md, R3).',
      body: 'Quiet fixes: the `undefined` held in a variable, which the parse reads as a value; every caller padded to pass as many arguments, so no witness passes fewer. Right: the operands not every caller supplies move into a trailing `opts = {}`; a class exempt under §3 reorders; an argument the hole reaches that is dead is deleted.' },
    EXTRA_ARGUMENT: { class: 'A',
      head: 'an argument no parameter receives.',
      body: 'Quiet fix: an unread parameter added to the callee to receive it. Right: delete the argument when it is dead; when the call reads differently than it compiles (a paren-less call swallowing the next line: buildSystem/compile-fragment.js shows the compiled form), spell it so it compiles to what is meant.' },
    POSITIONAL_INTO_OPTIONS: { class: 'A',
      head: 'a positional argument landing in an `opts = {}` slot, where it is taken AS the options object.',
      body: 'Quiet fix: a positional parameter added in front of the options slot to take it, which puts configuration in the identity head. Right: pass `key: value` pairs.' },
  },
  'check-menu-actions': {
    'RULE_1_FUNCTION_ACTION RULE_1B_UNRESOLVED_ACTION RULE_2_STRING_OPTS': { class: 'A',
      head: 'a menu row that throws when clicked: a row dispatches `@target[@action].call @target, menuItem, panelTarget, arg1, arg2`.',
      body: "Quiet fixes: a stub on a base class answering the action, which turns the click into nothing; the action's name built at run time, which this scan cannot read. Right: the action is a STRING naming a method that the target's class defines and that does the row's work, and the 4th argument is the options object." },
    RULE_3_UNREAD_PARAM: { class: 'B',
      head: 'a menu verb with a dispatcher slot it never reads, not named for what it skips.',
      body: "Quiet fixes: a trailing slot named `ignored` when it could be dropped; a read of the slot written only so it counts as read. Right: read it, or drop it and let the dispatcher's extra arguments fall away; a slot that exists only to reach a later one is named for that: `ignored`, `ignored2`, `unused`." },
  },
  'check-thin-wraps': {
    NOT_CANONICAL: { class: 'A',
      head: 'a method owning a `_<name>NoSettle` twin that does work of its own outside the one settle.',
      body: 'Quiet fixes: `# thin-wrap-exempt:` on a method whose work can move into its core; the twin renamed so the pair is not recognised. Right: move the work into `_<name>NoSettle`, leaving `[return if/unless guards] @_settleLayoutsAfter => @_<name>NoSettle <args>`. The marker, in the comment block directly above, answers a method that cannot be the mechanical wrap, and its reason says what it does that its core cannot.' },
  },
  'check-scheduled-checks': {
    OVERDUE: { class: 'B',
      head: 'a `# CHECK AFTER` reminder come due: the decision beside it is to be made again.',
      body: 'Quiet fix: a later date with nothing decided, which re-arms the reminder for the same question. Right: act on it — retire the workaround, or keep it and say why in its comment — and delete the marker; a later date is right only when the decision waits on something the comment names.' },
  },
  'check-stringified-scripts': {
    STRINGIFIED_SCRIPT: { class: 'B',
      head: 'code held as a string in core (`new ScriptWdgt """…"""`): code no gate reads and no class owns.',
      body: 'Quiet fixes: `# stringified-script-sanctioned:` with a reason that names no constraint ("temporary", "needed"); the string opened on the next line, which this scan does not see. Right: the script becomes user code or a real class. The marker answers a core site that must carry code as text, and its reason says why no class can hold it.' },
  },
  'check-region-markers': {
    'homepage macros videoplayer UNKNOWN_MARKER UNPAIRED_OPENER': RETIRED_MECHANISM,
  },
  'check-whole-file-markers': {
    'homepage macros video-player': RETIRED_MECHANISM,
  },
  'check-source-vault': {
    'coffeSource-global boot-window-key-scan': RETIRED_MECHANISM,
  },
  'check-relayout-repaints': {
    RETIRED_VERB: RETIRED_MECHANISM,
  },
  'check-part-edges': {
    UNGUARDED_CLASS_REF: { class: 'A',
      head: "a reference into a part with no guard: `<TheClass> is not defined` on an artifact without the part, or before a lazy part arrives.",
      body: 'Quiet fixes: an `if TheClass?` guard in front of a LAZY part\'s class, which turns the person\'s click into nothing; the class spelled as a string (`new (window["TheClass"])`), which this scan cannot see. Right: an eager part\'s site takes the guard; a lazy part\'s door awaits it — `world.parts.whenAllLoaded ["thePart"], ->` with the class named bare under it, or the app\'s class-level `requiredParts` — and a class name that arrives as data goes through `classNamed`. A class core cannot run without belongs in core.' },
    UNUSED_REQUIRES: { class: 'A',
      head: "a parts.json `requires` entry nothing backs: a fetch ordered fully first for a reason that no longer holds.",
      body: 'Quiet fix: a code reference to one of the required part\'s classes written only so the entry is backed. Right: delete the entry and its `//requires` reason; an entry stands while the requiring part\'s code needs a class of the required part defined first, and that code names it.' },
    'MEMBER_REFERENCE MEMBER_DISPATCHED_BY_NAME MEMBER_SUPER': { class: 'A',
      head: 'a reach of a member only another part installs: on an artifact without that part nothing implements it.',
      body: 'Quiet fixes: the member reached through a computed name (`x[name]()`), which this scan cannot see; a same-named definition in core written only so the member stops reading as the part\'s, which answers the call wrongly without the part. Right: guard the site for that part, as the lines above show — a part is all-or-nothing, so one of its members being here proves all of it is; a member a shipped product path needs is product: promote it out of the part.' },
  },
  'check-constructors-build': {
    CTOR_BUILDS_CHILDREN: { class: 'A',
      head: 'a constructor building its own children inline: `new X()` no longer returns settled.',
      body: 'Quiet fixes: `# constructor-build-exempt:` on a constructor whose building can move; the building done into a sub-child (`@contents._addNoSettle …`), which this scan does not match; the defer-to-attach `@_addNoSettle …; @_invalidateLayout()` spelled another way. Right: move the building into `_buildAndConnectChildrenNoSettle`, and call the settling `@_buildAndConnectChildren()` from the constructor. The marker answers a constructor that must build inline, and its reason says why the settled build cannot serve it.' },
  },
  'check-relayout-bounds-first': {
    'READS_BEFORE_APPLY HOOK_WITHOUT_TEMPLATE': { class: 'A',
      head: 'a layout pass reading its own geometry before its own bounds are applied: its children lag one cadence on a resize (the dpr-2 lag).',
      body: 'Quiet fixes: `# relayout-bounds-first-exempt:` on a pass whose read can move below the apply; the geometry read through an accessor this scan does not list, or from a copy stashed earlier, so the previous frame is read unseen. Right: apply own bounds first, or take the template shape (`@_reLayoutWithOwnContents`, the children placed in `_layOutOwnContents`), as the lines above show. The marker, directly above a `_reLayout` header, answers a pass that needs the previous frame, and its reason says why; a `_layOutOwnContents` hook takes no marker.' },
  },
  'check-back-buffer-memos': {
    MEMO_RIDES_A_SAVE: { class: 'A',
      head: 'a field written while the back buffer is built rides a save: a memo of a cache, which the restored widget trusts.',
      body: "Quiet fix: `# saved-content:` on a field that is a memo, which declares a cache to be the picture. Right: keep no memo (ask the raster, or paint unconditionally), or declare the field in the class's `@serializationTransients`. `# saved-content: <what makes it content>` on the field's declaration says what the field IS — the saved picture itself (`CanvasWdgt.drawnRaster`) — and is never a sanction." },
  },
  'check-page-loaded-elements': {
    'NOT_TRANSIENT NO_RESTORE_HOOK NO_COPY_HOOK UNATTRIBUTED_ELEMENT': { class: 'A',
      head: 'an element the page loads that a save or a copy carries, or loses.',
      body: 'Quiet fixes: `# page-element-not-held:` on an element a widget does hold; a hook defined only so it exists, which re-makes nothing. Right: keep the path in a field, declare the field holding the element in `@serializationTransients`, and re-make the element from the path in `_afterDeserialization` and `_reactToBeingCopied`. The marker, on the line, says why no widget holds an element (a decoder image, dropped once its pixels are in the canvas).' },
  },
  'check-raw-pointer-reads': {
    RAW_READ: { class: 'A',
      head: 'a pointer handler reading the hand in screen coordinates: right at offset 0, wrong once its plane is scrolled or tilted.',
      body: "Quiet fixes: the raw read moved into a helper the handler calls, which this scan does not read; `pos` mapped again — the `pos` a handler is handed is already in its plane, and mapping it as a screen point moves it. Right: consume `pos`; map only a raw screen read, on its line (`@screenPointToMyPlane world.hand.position()`). `# raw-screen-pointer-sanctioned: <reason>`, above the handler, answers one that wants the screen-plane sample itself, and its reason names what reads it there." },
  },
  'census-hierarchy-duplication': {
    IDENTICAL_OVERRIDE: { class: 'B',
      head: 'an override identical to the definition it inherits: the same code, with nothing bound to its class.',
      body: 'Quiet fixes: a cosmetic edit so the two bodies stop matching; `# identical-override-sanctioned:` with a reason that names no reader of ownership. Right: delete it, a comment on it that describes the subclass moving to the core it describes. The member then belongs to the base, and an inspector\'s own-member list shows it there (docs/architecture/widget-authoring-guidelines.md §16): a screenshot that changes with it is a recapture, never a reason to keep the copy. The marker, on or directly above the header, answers a reader whose behaviour needs this prototype to OWN the member (the menu sweep finds its contributors by the prototypes owning addWidgetSpecificMenuEntries), and its reason names that reader.' },
  },
  'check-method-categories': {
    'MARKER_MISPLACED CATEGORY_NAME_MALFORMED': { class: 'B',
      head: 'a `#:` line the meta-system reads as no marker: the members below it keep the category above it, or none, and nothing else says so.',
      body: 'Quiet fixes: the `#:` deleted so the line reads as a plain comment, which drops the category its author meant; a spelling the scan does not read as a marker-shaped comment (`# :`, `#;`). Right: the one form, `  #: <category>` at the member column between two members (two spaces, `#:`, one space, the name), its name lower-case words with one space between two, none of them opening with `extends` (the boot dependency scan reads an edge from one): docs/architecture/method-categories.md. A marker typed inside a body moves above the member it names; one above the class line moves below it, above the first member it names.' },
    STASH_HOLDS_CODE: { class: 'A',
      head: 'code the meta-system never compiles: a line between two members, above the class line or after the last member is no member\'s source, and it runs nowhere.',
      body: 'A comment or a marker at the member column (two spaces, then `#`) ends the member above it, so one typed inside a body cuts the body there and drops the rest of it here. Quiet fixes: the line commented out, which hides that it never ran; the line re-indented until it joins some member by accident. Right: find the member it belongs to — re-indent the comment or marker that cut it to the body\'s own indent, or move the marker above the member; a line that never ran and that nothing needs is deleted, the class\'s compiled output proved unchanged. A `###` block comment between members reads here too (its inner lines are no comment by Class.isAComment): write it as `#` lines.' },
    EMPTY_CATEGORY: { class: 'B',
      head: 'a category with no method under it: it names a group that holds nothing, and the method meant for it stands in another.',
      body: 'Quiet fixes: a field or a throwaway method put under it so it holds something. Right: the marker moves above the methods it names, or goes; a category may open more than once, so a method that belongs in an earlier one gets that marker again above it.' },
    MARKED_CLASS_UNMARKED_METHOD: { class: 'B',
      head: 'a method above its class\'s first marker: it stands in no category, in a class whose other methods each stand in one.',
      body: 'Quiet fixes: every method put under one marker (`private`, or one name for all) so none is above the first; the class\'s markers deleted so it counts as unmarked. Right: a marker above it naming what it does (docs/architecture/method-categories.md holds the recommended names, and a class may name its own); a class is marked whole or not at all.' },
    UNMARKED_CLASSES_ABOVE_BUDGET: { class: 'C',
      head: 'UNMARKED_CLASSES_BUDGET holds back classes landing with no categories: a class is cheapest to categorise as it is written.',
      body: 'First mark the new class whole: a marker above each group of its methods. A raise is right when the class comes out of an unmarked one by a mechanical move whose methods nobody re-read — a class split in two (one unmarked class becomes two: the count of its repo rises by one), or moved between the two repos (the count of the repo it lands in rises by one; a rename within a repo moves no count) — its dated reason beside the number. Markers placed by a name rule nobody read, or every method under one name, are the wrong answer.' },
  },
  // ---- the tests repo's static gates (Fizzygum-tests/scripts)
  'check-macro-source-discipline': {
    'TOOLKIT_EVAL UNDECLARED_EVAL': { class: 'A',
      head: 'code handed to an eval as a string where a macro body is already CoffeeScript: no binding for the widget, no syntax gate, no rename sweep reaches it, and it fails at run time where the statement fails at the build — and `@evaluateString` is the toolkit\'s own method besides, which binds `@` to the toolkit.',
      body: 'Quiet fixes: `@evaluateString` respelled `world.evaluateString` and the test then tagged `evaluateString`; the tag on a test whose subject is not the eval (the tag is the selection key, so it also enrols the test in the eval tag\'s run); the eval moved into a toolkit or harness method\'s body, which this scan does not read. Right: write the statement. The `evaluateString` tag, its why in the metadata, declares a test whose SUBJECT is `world.evaluateString` itself, and nothing else.' },
  },
  'check-refs': {
    'DUPLICATE_REFERENCE ORPHAN_REFERENCE': { class: 'A',
      head: 'a shot that is not one picture: a screenshot passes when it matches ANY candidate, so a stray hash lets a wrong render pass, and half a pair (a .js with no .png, a .png with no .js) is a picture nobody can review or nothing matches.',
      body: 'Quiet fix: deleting whichever file makes the count one — the committed reference, or every untracked file by habit (`git clean`) — without looking at which picture is right, which can delete the reference and keep the stray. Right: look at each picture, keep the one that shows what the test means and delete the rest, both halves of each; when the stray is the untracked file a capture undone with `git checkout` left behind, `node scripts/reset-test-refs.js <test>` restores the committed set. Then run the test: it passes against the one kept, or its render is the finding.' },
    STALE_AUTOMATOR_VERSION: { class: 'A',
      head: 'references captured by a harness that no longer exists: a screenshot matches its candidates whatever their version, so nothing at run time notices.',
      body: 'Quiet fix: a recapture of every reference so the versions line up, when the bump was not deliberate — it banks whatever renders today, a defect included, across the suite. Right: the version says what the harness captures, so it is bumped only by a harness change that alters the pixels a capture produces, and a bump made for anything else is reverted. A deliberate bump is followed by the recapture (`fg recapture --auto`), and the pixels that change are the ones that harness change predicts.' },
  },
  'aim-census': {
    UNCLASSIFIED_VERB: { class: 'B',
      head: "a toolkit verb no table classifies: every call of it reads as no aim, and as a press, so the census's counts miss whatever it aims.",
      body: "Quiet fix: the verb put in NON_AIM_VERBS, or in VERBS under whatever shape stops the line, without reading what it does at the pointer. Right: classify it by what it does: a verb that presses, moves, drags, drops or wheels at an argument goes in VERBS, that argument with its role, stating as its neighbours do what it resolves by meaning and whether it arms the aim check; NON_AIM_VERBS holds a verb that acts at wherever the pointer already is, under the kind that says what it does there." },
  },
  // ---- the gauntlet legs (Fizzygum-tests/scripts)
  'revisit-gate': {
    NEW_SIGNATURE: { class: 'A',
      head: 'a widget re-laid more than once in one flush: the settle engine visits every widget at most once per flush, so a re-visit is a convergence regression.',
      body: 'Quiet fixes: a flag or a non-notifying twin that skips the second visit; `--write-baseline` over the new signature, which banks the regression. Right: remove the cause — an arrange that is not idempotent, one that reads half-applied state, a container notified mid-arrange (docs/architecture/layout.md, the new-layout rulebook); the trace prelude above says who re-visited whom. A baseline entry records an owner\'s decision about a design, never the answer to a finding.' },
    VANISHED_SIGNATURE: { class: 'B',
      head: 'a re-visit the baseline holds no longer happens: an entry that excuses nothing.',
      body: 'Quiet fix: banking a vanish no change explains — a test that stopped reaching the path, or an instrument that stopped seeing it, retired nothing. Right: name the change that retired it, and bank it in that change: `--write-baseline` from a whole-suite run, the commit saying which change it was.' },
  },
  'settle-gate': {
    SETTLE_IN_CALLBACK: { class: 'A',
      head: 'a notification callback (`_reactTo*`/`_before*`) opened a settle of its own: the gesture or structural dispatcher owns the one `_settleLayoutsAfter`, and a callback is a settle-neutral core.',
      body: "Quiet fixes: the callback renamed out of `_reactTo*`/`_before*`, which this audit wraps by name; the settle deferred out of the callback's frame (a timer, a later cycle), where the frame no longer holds it. Right: move the settle to the dispatcher and keep the callback a settle-neutral core (docs/architecture/layering-naming-convention.md, rule [J])." },
  },
  'menu-click-sweep-headless': {
    'THREW PROMPT_OK_THREW': { class: 'A',
      head: "a menu row, or a prompt's OK, that throws when a person clicks it.",
      body: 'Quiet fixes: a `KNOWN` entry for a row that throws on a precondition — nothing made yet to act on, a state the walk does not set up; a `SKIP` or `SKIP_PROMPT` entry for a row a headless sweep can drive. Right: a `KNOWN` entry is right only where the throw IS the row\'s behaviour (the dev menu\'s "throw an error"); a row that throws because nothing is ready is the product\'s to fix: it refuses with a message, or is offered only when it can act.' },
    CONSOLE_ERROR: { class: 'A',
      head: 'the page logged an error, or threw, while the sweep fired its rows: a row that logs an error and returns has not run cleanly.',
      body: 'Quiet fix: a guard at the one leaf the sweep reached (`return unless @parent?`), which keeps the cause and drops the line. Right: find what the row left wrong, fix it where it lives, and ask which siblings share it.' },
    SUBMENU_FLAG_MISMATCH: { class: 'A',
      head: 'a row whose drawn chevron and whose act disagree: it opens a menu without saying so, or says so and opens none.',
      body: "Quiet fix: a `CONDITIONAL_OPENERS` entry for a row whose flag is simply wrong, which keeps the chevron lying. Right: the row's `opensSubmenu` (addMenuItem's opts) states what the row does. An entry, keyed `<receiverClass>.<action>` and excusing one direction, is right only for a row that opens a menu exactly when something it stands for does (the overflow chevron's projection of a tool), and its reason names that." },
  },
  'pin-sweep-headless': {
    'NO_SETTER NO_GETTER NO_SETTER_FOR_APPEARANCE_PIN': { class: 'A',
      head: 'a pin naming a setter or getter its class does not have: the dataflow dispatches it by name with `?.`, so the pin is offered, takes a wire, and silently does nothing.',
      body: "Quiet fixes: a stub that answers the name and does nothing; the pin dropped from a class that does have the property it names. Right: write the member the pin names, on the class that advertises it (a widget wearing the appearance, for an appearance's pin), doing what the pin promises. A class without that property declines the pin where it composes its pins (a subclass narrowing the helper, as DiffingPatchNodeWdgt does)." },
  },
  'staleness-census': {
    'AS_BUILT_MOVER POST_RESIZE_MOVER': { class: 'A',
      head: 'a widget whose subtree moves when re-laid at its own converged frame: it was sitting at stale geometry, or its arrange is not idempotent.',
      body: "Quiet fixes: a `KNOWN_MOVERS` entry for its class, which reports the mover as known and keeps it; a re-lay or a resize added to the app's opening flow so the widget converges before the sweep reads it, which hides a widget laid out wrong as built. Right: fix that widget's arrange — build it at the geometry it settles to, and make a re-run at the converged frame move nothing (the case law in this census's header)." },
  },
  'run-all-headless': {
    SCREENSHOT_MISMATCH: { class: 'A',
      head: 'a screenshot that matches no reference: the world drew something else.',
      body: 'Quiet fixes: a recapture without looking, or of more tests than the change predicts, which banks whatever renders today, a defect included; the shot taken out of the macro, which then checks less; a re-run until it passes, which hides a nondeterminism (Fizzygum-tests/DETERMINISM.md). Right: look at the diff page first (`fg diffpage <test>`). A picture the change is meant to alter is recaptured with the set the change predicts (`fg recapture --auto`); any other is a finding about the change, fixed at its cause. A reference never banks a defect.' },
    AMBIGUOUS_REFERENCES: { class: 'A',
      head: 'two pictures on disk for one shot at one Automator version: a stray, which would let a wrong render pass, so the shot fails outright.',
      body: 'Quiet fix: deleting whichever file makes the count one — the committed reference, or every untracked file by habit (`git clean`) — without looking at which picture is right, which can delete the reference and keep the stray. Right: look at each picture, keep the one that shows what the test means and delete the other; when the stray is the untracked file a capture undone with `git checkout` left behind, `node scripts/reset-test-refs.js <test>` restores the committed set. Then run the test.' },
    MACRO_INCOMPLETE: { class: 'A',
      head: 'a test took fewer screenshots than its macro declares: the macro stopped early, most likely on an error it swallowed.',
      body: 'Quiet fixes: the shot the macro did not reach taken out of its source, which then checks less; a catch around the step that stopped it. Right: run the test alone (`node scripts/run-macro-test-headless.js <test> --all-logs`), find what ended the macro early, and fix that.' },
    ASSERTION_FAILED: { class: 'A',
      head: "a macro's assertion found something other than what it expects.",
      body: 'Quiet fixes: the expected value changed to what was found, with no change that predicts it; the assertion loosened or deleted; a toolkit verb that rescues the step, so the assertion meets what it expects for the wrong reason. Right: decide which is wrong — the product, fixed at its cause, or an expectation the change is meant to move, rewritten in that change and saying why. A line that carries its own advice (an aim missed) says the rest.' },
    'PAINT_ERROR STEP_ERROR INPUT_ERROR': { class: 'A',
      head: "a paint, a step or an input event's handling threw, caught where the world survives it.",
      body: "Quiet fix: `expectsCaughtErrors` declaring the token in a test whose subject is not that catch, which excuses the throw for the whole test. Right: fix what threw. The declaration, with its `caughtErrorsReason`, is right only when the test's SUBJECT is that catch (a person's own code throwing there, and the world telling them), and it names exactly the tokens the test provokes on purpose." },
    // every other failing console line: each gate token (Fizzygum-tests/scripts/lib/gate-tokens.js), an untokenized
    // error, an uncaught page error, an error led by a word the list does not hold
    [ANY]: { class: 'A',
      head: "a failing console line: the world reported something wrong (geometry, layout, paint, storage, lifetime, boot), and the line's own text says what.",
      body: 'Quiet fixes: a guard at the leaf that emitted the line, which stops the line and keeps the cause; a value rounded, clamped or defaulted where the line reads it rather than where it is produced; an exemption or allowlist entry for it; the report stripped of its token and demoted to a console.log, a line no runner fails on (a line carrying a token fails whatever its kind, and an error line unless a by-design token opens it). Right: read the line, find what produced the wrong state, and fix it there; a line that carries its own advice says the rest.' },
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

// The rows of `gate` whose key names an id, by id → { key, row }.
function namedRowsOf(gate) {
  const byId = new Map();
  for (const [key, row] of Object.entries(ROWS[gate] || {})) {
    if (key !== ANY) for (const id of key.split(' ')) byId.set(id, { key, row });
  }
  return byId;
}

// The row of `gate` that serves an id: a function from the id to { key, row } — the row whose key names it (split at
// spaces), else the gate's `*` row, else undefined.
function rowsOf(gate) {
  const byId = namedRowsOf(gate);
  const any = Object.prototype.hasOwnProperty.call(ROWS[gate] || {}, ANY) ? { key: ANY, row: ROWS[gate][ANY] } : undefined;
  return (id) => byId.get(id) || any;
}

// The ids among `ids` (a gate's fired rules, in their order) that a row of `gate` NAMES: the advice the gate prints. A
// `*` row serves only the ids its gate passes for it.
function advisedAmong(gate, ids) {
  const byId = namedRowsOf(gate);
  return [...new Set(ids)].filter((id) => byId.has(id));
}

// The lines a gate prints for the rules `ids`: each row once, in the order its first id is given, its header naming
// every id given that it serves; then the shared text of each class among them, once. No id, no line. An id with no
// row stops the gate: exit 2, ADVICE_ROW_MISSING.
function adviceLines(gate, ids) {
  const rowOf = rowsOf(gate);
  const asked = [...new Set(ids)];
  const missing = asked.filter((id) => !rowOf(id));
  if (missing.length) {
    writeAll(2, `[${gate}] ADVICE_ROW_MISSING ${missing.join(' ')} — lib/gate-advice.js holds no row for it: write the row (what its finding means, its quiet fixes and the right answer), or print no advice for it\n`);
    process.exit(2);
  }
  const lines = [];
  const classes = [];
  const printed = new Set();
  for (const id of asked) {
    const { key, row } = rowOf(id);
    if (printed.has(key)) continue;
    printed.add(key);
    const named = asked.filter((other) => rowOf(other).key === key);
    lines.push(...wrap(row.head, `[${gate}] ADVICE ${named.join(' ')} — `), ...wrap(row.body, INDENT));
    if (!classes.includes(row.class)) classes.push(row.class);
  }
  for (const c of classes) {
    lines.push(...wrap(CLASSES[c].head, `[${gate}] `));
    for (const paragraph of CLASSES[c].body) lines.push(...wrap(paragraph, INDENT));
  }
  return lines;
}

// a header: its gate, and the ids it names, separated by single spaces
const ADVICE_LINE_RE = /^\[([\w.-]+)\] ADVICE ([A-Za-z0-9][\w.-]*(?: [A-Za-z0-9][\w.-]*)*) — /gm;

// What `out` holds of the advice of the gate named `gate`: a Map from each id an ADVICE header of it names to the
// number of times a header names it. A row several rules share is owed one header however many of its ids it names;
// printed under more than one header, it enters the Map too, as `<its ids joined by +>-row` (`*-row` for the row
// keyed `*`) → that number. A class's
// shared text is owed exactly once by a run that prints a row of that class, and never otherwise; printed any other
// number of times it enters the Map too, as `<class>-shared-text` → that number. So advice printed right reads as its
// ids, each once, and a judge holding the Map to that sees a header, a row or a shared text doubled, or missing.
// Another gate's advice (one gate run inside another prints both) is not this gate's.
function parseAdvice(out, gate) {
  const text = String(out || '');
  const rowOf = rowsOf(gate);
  const counts = new Map();
  const headersOfRow = new Map();
  for (const m of text.matchAll(new RegExp(ADVICE_LINE_RE.source, 'gm'))) {
    if (m[1] !== gate) continue;
    const ids = m[2].split(' ');
    for (const id of ids) counts.set(id, (counts.get(id) || 0) + 1);
    for (const key of new Set(ids.filter((id) => rowOf(id)).map((id) => rowOf(id).key))) {
      headersOfRow.set(key, (headersOfRow.get(key) || 0) + 1);
    }
  }
  for (const [key, n] of headersOfRow) {
    if (n > 1 && (key.includes(' ') || key === ANY)) counts.set(`${key.split(' ').join('+')}-row`, n);
  }
  const lines = text.split('\n');
  for (const [c, shared] of Object.entries(CLASSES)) {
    const opening = wrap(shared.head, `[${gate}] `)[0];
    const printedTimes = lines.filter((l) => l === opening).length;
    const owed = [...counts.keys()].some((id) => rowOf(id) && rowOf(id).row.class === c) ? 1 : 0;
    if (printedTimes !== owed) counts.set(`${c}-shared-text`, printedTimes);
  }
  return counts;
}

module.exports = { adviceLines, advisedAmong, parseAdvice, ADVICE_LINE_RE, ROWS, CLASSES, ANY };

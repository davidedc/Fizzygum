#!/usr/bin/env node
// check-stinks.js — build gate for "STINKS": code smells we are driving to zero, each RATCHETED at
// a baseline count (mirrors buildSystem/check-dead-methods.js, which ratchets dead code via an
// allowlist; and check-layering.js, which fails on any violation).
//
// Each stink carries a `baseline` — the max occurrences currently tolerated. The build FAILS when a
// stink EXCEEDS its baseline (a regression). When a stink drops BELOW its baseline you have driven
// it down: tighten the baseline in THIS file to lock the gain in (the check prints a reminder). A
// stink at baseline 0 is a HARD rule — any occurrence fails the build. There is no separate
// allowlist file: the baseline lives inline next to the rule, since a smell is a count, not a set of
// named methods.
//
// Add a new {id, baseline, why, re} to STINKS below to ratchet the next smell. `why` is not
// decoration — it is what a future reader gets INSTEAD of the arguing; write it for someone who
// does not already agree.
//
// Scope: src/**/*.coffee only (NOT the sibling test harness) — a stink is a statement about the
// SHIPPED framework's idiom. Per-LINE regex over `#`-comment-stripped lines; there is no multi-line
// matcher (an empty-catch stink would need one — plan §8.9).
//
// A stink may instead declare `scope: 'comments'` to match the COMMENT part of each line (from the
// first `#` onward) rather than the code part — the comment-hygiene ratchets (2026-07-17 comments
// cleanup) use this: comments must state present-tense constraints, not narrate history or carry
// meta-edits/debug residue (history's home is docs/archive/ — see docs/README.md filing rules).
// NB the naive `#` split means a `#` inside a string counts as a comment start here; accepted for
// the same measures-regression-not-absolutes reason as above.
//
// A stink may declare `exclude`: a list of src-relative path PREFIXES whose files it does not scan
// — a directory (`'demos/'`, which covers its subdirectories too) or a file (`'Theme.coffee'`). Use
// it when a smell is a smell only OUTSIDE some places (a colour literal is a look decision in a
// chrome file and plain data in a demo). Every file the list does not name is scanned, so a NEW
// file is counted by default; an exclusion is a decision someone wrote down, never an accident.
//
// A stink may declare `sanctioned`: a list of { file, member, count, why } naming the sites INSIDE
// scanned files where a hit is not the smell — a literal that is data, not a look decision. `file`
// is src-relative; `member` is the hit's ENCLOSING MEMBER (the nearest class-body key above it at
// the 2-space indent — a method, a field, a static `@NAME` —, or in a mixin file the nearest key at
// the indent of its instance-property hash's members, the one the shared grouping locks
// (lib/coffee-method-header.js mixinMemberIndent: 4 or 6 spaces); a deeper key is an option
// object's and never names a member). A group of hits matching an entry is not counted against the
// baseline when its size equals `count` EXACTLY; otherwise the entry FAILS the build — 0 hits is a
// STALE entry (delete it), any other number is a COUNT mismatch (a literal was added to or removed
// from a sanctioned member: decide again). So the list is a DECLARATION, never a hiding place: it
// cannot outlive what it names, and it cannot silently absorb a new literal. `--list` prints the
// sanctioned hits apart, each with its `why`.
//
// A code-scope stink may declare `stringAware: true` to cut the comment at the first `#` that sits
// OUTSIDE a quoted string ('…', "…" incl. its `#{…}` interpolation, `…`), so a literal written
// inside a string — a CSS `'#rrggbb'` — stays visible to `re`; the default naive cut takes that
// `#` for a comment start and hides the rest of the line. A per-line scan cannot follow a string
// across lines (`'''`/`"""` blocks) or into a regex literal; the naive cut has the same blind spots.
//
// (Historical: the original settle-batch-with-core stink was retired when its target,
// _settleLayoutsAfterBatch, was deleted, leaving the table empty until the 2026-07-15 seeding.)

const fs = require('fs');
const path = require('path');
const { mixinMemberIndent } = require('./lib/coffee-method-header');   // a mixin hash's member indent

const SRC = path.resolve(__dirname, '../src');

// Seeded 2026-07-15 (docs/archive/lint-generic-rules-carryover-plan.md Phase 2), carrying over the generic
// cruft/idiom rules from Pharo's SmallLint/Renraku catalogue. Every baseline below was MEASURED by
// this engine on the day (never estimated) and every stink was spot-checked against its real hits.
// These are RATCHETS, not verdicts: each records today's count so the number can only fall. Driving
// any of them down is a FUTURE arc — the seeding arc deliberately changed no src.
//
// NB the counts are the ENGINE's, and stripComment (below) is a naive `#` cut that does NOT mask
// STRINGS — so e.g. undefined-literal counts `typeof x is 'undefined'`. That is accepted: a ratchet
// measures REGRESSION, not an absolute. (Masking upgrade = plan §8.8 backlog.)
const STINKS = [
  { id: 'debugger-statement', baseline: 33,   // Pharo: ReCodeCruftLeftInMethodsRule; tightened 36->33 on 2026-07-30 (banking a gain already landed; fg critique surfaced it)
    why: 'a debugger statement is left-in debug cruft; it hard-stops execution whenever devtools are open',
    re: /^\s*debugger\b/ },
  // `undefined-literal` (baseline 83) was DELETED on 2026-08-13: it enforced `nil` OVER `undefined`,
  // and the `nil` global it protected has been retired, so the rule now polices the opposite of the
  // convention. `nil-literal` is its replacement — same intent, inverted direction.
  { id: 'nil-literal', baseline: 0,   // HARD: `nil` no longer exists; a reference to it is a ReferenceError waiting to happen
    why: "the `nil = undefined` global is RETIRED — `undefined` is the codebase's one absence value, spelled the way the language spells it. `nil` was an alias for a primitive that cost a writable global, a boot-order dependency and a lint rule, and had leaked into the reflective layer as emitted source",
    re: /\bnil\b/ },
  { id: 'null-literal', baseline: 8,   // tightened 9->8 on 2026-08-13 (the DemoMenus stack-panel `null`s were a live CS2 default-param bug)
    why: "the codebase uses `undefined` as its ONE absence value, never `null` — the JS-interop sites (JSON.stringify's arg, DOM `onload = null`) are the tolerated tail",
    re: /\bnull\b/ },
  { id: 'wall-clock', baseline: 19,
    why: 'Date.now()/new Date() in framework code breaks event-stream determinism (Fizzygum-tests/DETERMINISM.md; multi-click recognition keys off EVENT timestamps, never the wall clock)',
    re: /\b(Date\.now\s*\(|new Date\s*\()/ },
  { id: 'timer', baseline: 4,   // raised 3->4 on 2026-08-04: SourceCompileScheduler._ensurePumpScheduled pumps the compile-at-boot ingest, which runs only while NO world exists (same nature as the waitNextJSEventLoopCycle timer beside it) — bug-class B needs a live suite world to bite
    why: 'setTimeout/setInterval diverge at dpr2 under parallel load (DETERMINISM.md bug-class B: heavy cycles starve timers); the cycle/step machinery is the sanctioned clock',
    re: /\b(setTimeout|setInterval)\s*\(/ },
  { id: 'math-random', baseline: 5,
    why: 'Math.random in render/layout/input code breaks byte-exact screenshot determinism',
    re: /\bMath\.random\b/ },
  { id: 'instanceof-type-test', baseline: 75,   // Pharo: ReBadMessageRule (isKindOf:); tightened 105->97 (2026-07-17); 97->95 (2026-07-18, DividerWdgt.isDivider role query retired 2 `instanceof DividerWdgt` in removeConsecutiveLines); 95->93 (2026-07-30, banking a gain already landed; fg critique surfaced it); 93->88 (2026-08-04, layout spec-family arc: the enum dispatch + 5 spec-class instanceofs became capability queries); 88->87 (2026-08-09, banking a gain already landed; surfaced by the comments-audit stink run); 87->77 (2026-08-19, scroll-frame role arc: the viewport/plane role queries retired the composite's instanceof tests; surfaced by the comments-audit stink run); 77->78 (2026-08-19, paint-time-scroll-translation Phase 1: Widget._enclosingMappedPlaneRoot is a new canonical mapping walk and uses the walks' one island test); 78->81 (2026-08-20, WorldInventory: a reflective walker over arbitrary/host objects needs 3 tests no polymorphism can express — Widget for zombie identity, Node for DOM leaves, ArrayBuffer for typed-array leaves; the Map/Set tests delegate to NativeValueKinds); 81->80 (2026-08-26, gesture grammar P2: the macro toolkit's move verb resolved a Widget target to a screen point TWICE inline, and the finger verbs need the same resolution -- one _screenPointOfTarget now answers for all of them); 80->77 (2026-10-16, banking a gain gesture grammar P3 landed on 2026-08-26 without tightening: the macro toolkit's _widgetOfTarget decides "which widget" a verb was aimed at in one place, so four inline `instanceof Array` identifier tests became one; surfaced by this gate's own UNDER line); 77->76 (2026-10-18, redesign W2: the tooltip lays its text out one TextWdgt per line and no longer type-tests its contents widget); 76->75 (2026-10-20, redesign W5: the vertical stack picks a drop's slot by its children's middles, and its `instanceof Point` guard on the drop point goes)
    why: 'the type-test-elimination campaign drove instanceof down; this locks the tail against regrowth — prefer polymorphism',
    re: /\binstanceof\b/ },
  { id: 'positional-hole', baseline: 0,   // HARD as of 2026-08-16: the conformance arc drove this to zero and there is no site left to grandfather. Seeded 2026-08-15 at THIS engine's own count (51); tightened 51->30 (plan P2, the text family), 30->28 (P3, the button family), 28->25 (P5, the stragglers), 25->1 (P6, the METHOD families), 1->0 (P7, the `add` family). P4 moved it by zero and that was correct: every hole it removed spans MULTIPLE lines and this regex needs two `undefined`s adjacent on ONE — so a PASS here is a floor, not a proof. The HONEST count lives in buildSystem/check-argument-holes.js, which shares census-call-arity.js's paren-aware parser and catches the single-`undefined` and multi-line holes this regex cannot see. Keep this stink anyway: it is the instant alarm for the worst shape, at zero cost, inside the pass that is already running

    why: 'a call punching `undefined` through to reach a later argument PROVES the skipped parameter is configuration rather than identity — no single order can serve callers wanting disjoint tails. The remedy is a trailing `opts = {}` object (or, for an exempt value class, a reorder): docs/architecture/constructor-and-parameter-conventions.md R3',
    re: /\bundefined\b\s*,\s*\bundefined\b/ },
  { id: 'helper-compiling-operator', baseline: 0,   // HARD from the day it was added (2026-08-17): src was already at zero, and every site this can match is a guaranteed runtime ReferenceError
    why: "CoffeeScript compiles `%%` into a `modulo` HELPER FUNCTION declared in the emitted `var` block — and the meta-system STRIPS that block out of every member it compiles (src/meta/Class.coffee _removeHelperFunctions, `/^var(.|\\n)*?\\(function/`), so the operator becomes a call to something that does not exist. Nothing else catches it: it parses, so the syntax gate passes it, and the strip's own guard enumerates only three helper names (indexOf/hasProp/slice) — it does not know about this one. The failure surfaces as a widget BANNED FROM REPAINTING with `ReferenceError: modulo is not defined` in the error log, i.e. as a screenshot diff. Spell the wrap out (`x += 6 if x < 0`)",
    re: /%%/ },
  { id: 'raw-chrome-color', baseline: 0,   // seeded 2026-10-17 at THIS engine's own count (98), once the shadow silhouettes read their Theme role (redesign plan §4 F1); 98->96 on 2026-10-17 (redesign W1: the pencil/eye button takes its strip's inks and drops its two class-level colours); 96->91 on 2026-10-18 (redesign W2: menu rows and magnets read their state fills from roles, LabelButtonWdgt's two class-level colours go; the scroll thumb's colour is a function of its presentation and state, SliderButtonWdgt's three go); 91->90 on 2026-10-18 (redesign W3: the Object Inspector's code-pane text background reads its role); 90->82 on 2026-10-19 (redesign W4: DesktopLinkWdgt's three class-level state colours go, its tile reading the desktopIconTile* roles, and so do the clock's five leftovers, its face, marks and hands reading the clock* roles); 82->72 on 2026-10-20 (redesign W5: the toolbar tools' class-level state colours go, the tool cell deriving its look from roles — CreatorButtonWdgt 3, EditorContentPropertyChangerButtonWdgt 3, PaintToolbarWdgt's orange armed-tool ink 1 — and the document page's 249 literals read roles — SimpleTextWdgt's blend 2, VerticalStackViewportWdgt 1); 72->65 on 2026-10-21 (redesign G-A: the spreadsheet's 7 look colours go, its cells and headers reading the spreadsheet* roles at paint and build time); 65->59 on 2026-10-21 (redesign G-B: the drag outline paints a ring and no fill, so HighlighterWdgt's transparent clear goes; the droplet becomes a well read from roles at paint, its three class-level state colours and two literals go); 59->51 on 2026-10-21 (redesign G-C: the colour picker's background and the palette's choice-marker rings read their roles at paint — ColorPickerWdgt 1, PaletteAppearance 4 — and a text area's text background is one role, so TextAreaWdgt's yellow default and its and CodeAreaWdgt's transparent clears go); 51->48 on 2026-10-21 (redesign G-D: a text's selection reads its roles at paint, so StringWdgt's class-level markedTextColor / markedBackgroundColor go, and blanksColor, which nothing read).; 48->13 on 2026-10-22 (redesign G-E: the 35 literals in counted files that are data, not a look decision, are DECLARED in `sanctioned` below, each with its reason, so the count is chrome only); 13->2 on 2026-10-22 (redesign G-E1: state colours read roles at each state change — HighlightableMixin's 3, ButtonWdgt's, the edit mark's, the icon buttons' two hovers — SwitchButtonWdgt's 3 unread colours go, and a canvas's paper reads canvasFill as its raster is made); 2->1 on 2026-10-22 (redesign G-E3: the header-line rule reads headerLineRule as it paints); 1->0 on 2026-10-22 (redesign G-E2: a text with no colour of its own holds none and paints in the defaultTextInk role, read as it paints) — now a HARD rule: a chrome look decided outside Theme fails the build; a literal that is data is declared in `sanctioned` — `--list raw-chrome-color` enumerates them, and the sanctioned sites apart
    why: "the LOOK of chrome is decided in ONE place, src/Theme.coffee (docs/architecture/visual-design-system.md): its palette, and the role each surface paints with. A colour literal in a chrome file is a look decided OUTSIDE that design system — a restyle edits Theme and cannot reach it, so that surface keeps the old look while everything around it moves, and nothing reports the miss. Read the surface's role instead (`WorldWdgt.theme.<role>`), adding a role when the surface has none. `exclude` names the places where a literal is NOT a chrome look decision: Theme itself, the Color class and value plumbing, CONTENT (demos, sample widgets, plots, maps, examples, fizzytiles, the video player) and ICON art. The tolerated tail is the class-level state colours (a class-level declaration may not reference another class, so they move with their family's wave), the desktop wallpaper patterns (a wallpaper design's own colours), transparent clears, plus the non-chrome literals that live in counted files; it ratchets toward 0",
    exclude: [
      'Theme.coffee',                                          // where the values live
      'basic-data-structures/', 'boot/', 'serialization/',     // the Color class itself and value plumbing
      'demos/', 'dev-tools/', 'graphs-plots-charts/', 'maps/', // CONTENT: a literal is the content's own colour
      'examples/', 'fizzytiles/', 'video-player/',
      // (spreadsheet/ is COUNTED: its grid header, gridlines and selection are the sheet's chrome)
      'patch-programming-experimental/',                       // ICON art (its Fanout*Appearance classes are IconAppearances)
      'icons/', 'icons-dev/', 'authoring-icons/', 'demos-icons/', 'examples-icons/',
    ],
    // the literals inside counted files that are DATA, not a chrome look decision (header comment: an entry
    // fails once its member holds a different number of hits, so it cannot outlive or widen what it names)
    sanctioned: [
      { file: 'DesktopAppearance.coffee', member: '_setUpBackgroundPattern', count: 12, why: "a wallpaper pattern's own colours: a design the user picks, not chrome" },
      { file: 'GrayPaletteWdgt.coffee', member: 'fillPaletteBuffer', count: 2, why: 'palette data: the black-to-white gradient IS the content' },
      { file: 'ColorPickerWdgt.coffee', member: 'constructor', count: 1, why: 'a value: the choice a picker opens with when given none' },
      { file: 'basic-widgets/Widget.coffee', member: 'color', count: 1, why: "a new shape's declared content default (plan §4 G \"Decisions settled\", Defaults)" },
      { file: 'basic-widgets/Widget.coffee', member: 'popUpColorSetter', count: 1, why: 'a value: the colour the colour prompt opens at' },
      { file: 'authoring/PaintToolbarWdgt.coffee', member: '@PENCIL_TOOL_SOURCE', count: 2, why: "a paint tool's source text, which the user reads and edits: content" },
      { file: 'authoring/PaintToolbarWdgt.coffee', member: '@BRUSH_TOOL_SOURCE', count: 3, why: "a paint tool's source text, which the user reads and edits: content" },
      { file: 'authoring/PaintToolbarWdgt.coffee', member: '@TOOTHPASTE_TOOL_SOURCE', count: 5, why: "a paint tool's source text, which the user reads and edits: content" },
      { file: 'authoring/PaintToolbarWdgt.coffee', member: '@ERASER_TOOL_SOURCE', count: 3, why: "a paint tool's source text, which the user reads and edits: content" },
      { file: 'PreferencesAndSettings.coffee', member: 'getMinimumFontHeight', count: 1, why: 'a throwaway calibration rasterisation, never shown' },
      { file: 'WorldWdgt.coffee', member: '_showDamageRects', count: 1, why: 'the debug damage overlay: random colours by design' },
      { file: 'WorldWdgt.coffee', member: '_initVirtualKeyboard', count: 2, why: 'styling of an invisible DOM <input>, not canvas paint' },
      { file: 'mixins/BackBufferMixin.coffee', member: 'getPixelColor', count: 1, why: 'value plumbing: a Color built from read pixel bytes' },
    ],
    stringAware: true,   // a CSS colour lives in a string ('#325FA2'); the naive cut would hide it
    re: /\bColor\.create|\bnew Color\b|\bColor\.[A-Z][A-Z0-9_]*\b|(['"])#(?:[0-9A-Fa-f]{3,4}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})\1|['"]rgba?\(/ },
  // Comment-hygiene ratchets (2026-07-17 comments cleanup; baselines measured post-cleanup).
  { id: 'comment-meta-edit', baseline: 0, scope: 'comments',
    why: 'a comment arguing with itself ("the below is actually correct", "to be clear") is process residue — state the surviving constraint once, plainly',
    re: /\b(the (below|above) is|is actually (correct|right|fine|wrong)|to be clear,)\b/i },
  { id: 'comment-narration', baseline: 87, scope: 'comments',   // tightened 105->104 on 2026-08-04 (comments-audit sweep removed one; locking the gain in); 104->103 on 2026-08-15 (MenuItemSpec's header stopped narrating what its constructor replaced when that constructor changed again); 103->102 on 2026-08-18 (SwitchButtonWdgt's setter comments rewritten in the settle-grammar conformance); 102->101 on 2026-08-21 (the shared teardown core's contract block stopped narrating what the two callers "used to" look like and states the two obligations instead); 101->100 on 2026-08-21 (the pointer hit-test rework: MenuWdgt's block states which object owns the shape answer instead of which one carried it before); 100->99 on 2026-08-25 (command-panel unification P1: de-positionalizing MenuItemWdgt.menuEntryPreferredWidth off @children[0] dropped its history receipt about the `debugger` statement the guard replaced -- the comment now states what the measure reads and why, by name); 99->96 on 2026-10-17 (redesign W1: the frame, strip and handle comments the wave rewrote state constraints instead of what they replaced); 96->92 on 2026-10-19 (redesign W4: the rewritten clock appearance and desktop-icon holder state what they draw instead of what they replaced); 92->91 on 2026-10-20 (redesign W5: the toolbar text tools' base class states what its tools share instead of what they once extended); 91->90 on 2026-10-21 (redesign G-A: the C-F demo icon states it inherits its parent's art instead of what it used to copy); 90->88 on 2026-10-21 (redesign G-B: HighlighterWdgt's header and style channel state its two forms instead of what it used to do and no longer uses); 88->87 on 2026-10-25 (residue-2 arc: ViewportWdgt's release-flush comment states the cadence-collapse rule instead of what the old flush used to drop)
    why: 'history narration ("used to", "previously", "no longer", "in the old model") belongs in docs/archive/ with a pointer, not inline — a comment states what IS',
    re: /\b(used to\b|previously\b|no longer\b|in the old (model|way|code)\b)/i },
  { id: 'commented-out-debug', baseline: 0, scope: 'comments',
    why: 'commented-out alert/debugger/console.log is dead debug cruft — delete it; git remembers',
    re: /^#\s*(alert\s*\(|debugger\b|console\.log\s*[\('"])/ },
  { id: 'comment-past-receipt', baseline: 0, scope: 'comments',   // seeded at 33 and swept to ZERO the same day (2026-08-09) -- now a HARD rule; the sweep's translation idiom is "instead of <old expr>" (present-tense design statement, old expression kept as the contract spec)
    why: 'a "was <old code>" conversion receipt narrates history — state the surviving present-tense contract (what the predicate answers, or why this spelling) and let docs/archive/ keep the before-picture. EXCEPTION judged per-site at sweep time: an old expression that documents COMPOUND semantics the new form must preserve gets TRANSLATED into a present-tense contract, not deleted.',
    re: /\b(was|were) `|\bthis once was\b|\bformerly\b|\brenamed from\b/i },
];

function walk(dir, acc) {
  if (!fs.existsSync(dir)) return acc;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (e.name.endsWith('.coffee')) acc.push(p);
  }
  return acc;
}
function stripComment(line) { const i = line.indexOf('#'); return i < 0 ? line : line.slice(0, i); }
function commentPart(line) { const i = line.indexOf('#'); return i < 0 ? null : line.slice(i); }
// the `stringAware` cut: the code before the first `#` outside a quoted string (header comment)
function stripCommentOutsideStrings(line) {
  let quote = null;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (quote) {
      if (c === '\\') i++;
      else if (c === quote) quote = null;
    } else if (c === '"' || c === "'" || c === '`') quote = c;
    else if (c === '#') return line.slice(0, i);
  }
  return line;
}
// src-relative, '/'-separated: the form `exclude` prefixes and `sanctioned` files are written in
const srcRelative = p => path.relative(SRC, p).split(path.sep).join('/');

// the ENCLOSING MEMBER of line i, as `sanctioned` names it (header comment): the nearest class-body
// key above at the 2-space indent, or — in a mixin file — at `memberIndent`, the indent its hash's
// members sit at (mixinMemberIndent; undefined for a file with no mixin member). A member is any KEY
// there, a data member's as well as a method's, because a sanctioned literal can sit in a field.
const CLASS_BODY_KEY = /^  (@?[A-Za-z_$][\w$]*)\s*:/;
function enclosingMember(lines, i, memberIndent) {
  const memberKey = memberIndent === undefined ? undefined : new RegExp(`^ {${memberIndent}}(@?[A-Za-z_$][\\w$]*)\\s*:`);
  for (let j = i; j >= 0; j--) {
    const m = lines[j].match(CLASS_BODY_KEY) || (memberKey && lines[j].match(memberKey));
    if (m) return m[1];
  }
  return '(top)';
}

// --list <stink-id>: print every site of ONE stink and exit — a sweep enumerator, not a gate
// (the comments-side twin of check-doc-narration's --full). Reached as `fg stinks --list <id>`.
const listIdx = process.argv.indexOf('--list');
const listId = listIdx >= 0 ? process.argv[listIdx + 1] : null;
if (listIdx >= 0 && !STINKS.some(s => s.id === listId)) {
  console.error(`[stinks] unknown stink id '${listId}' — known: ${STINKS.map(s => s.id).join(', ')}`);
  process.exit(2);
}

const files = walk(SRC, []);
let over = 0;        // total occurrences ABOVE baseline (a build failure)
let ratchetable = 0; // stinks now BELOW baseline (a chance to tighten)
let badSanctions = 0; // STALE or COUNT-mismatched `sanctioned` entries (a build failure)
for (const stink of STINKS) {
  if (listId && stink.id !== listId) continue;
  const baseline = stink.baseline || 0;
  let hits = [];
  const groups = new Map();   // `${file}::${member}` -> its hits, when the stink declares `sanctioned`
  const codeCut = stink.stringAware ? stripCommentOutsideStrings : stripComment;
  for (const p of files) {
    const rel = srcRelative(p);
    if (stink.exclude && stink.exclude.some(prefix => rel.startsWith(prefix))) continue;
    const text = fs.readFileSync(p, 'utf8');
    const lines = text.split('\n');
    const memberIndent = stink.sanctioned ? mixinMemberIndent(lines) : undefined;
    lines.forEach((line, i) => {
      const subject = stink.scope === 'comments' ? commentPart(line) : codeCut(line);
      if (subject === null || !stink.re.test(subject)) return;
      const hit = `${path.relative(SRC, p)}:${i + 1}: ${line.trim()}`;
      hits.push(hit);
      if (stink.sanctioned) {
        const key = `${rel}::${enclosingMember(lines, i, memberIndent)}`;
        if (!groups.has(key)) groups.set(key, []);
        groups.get(key).push(hit);
      }
    });
  }
  const sanctionedHits = [];   // [hit, why]
  const sanctionFailures = [];
  for (const s of stink.sanctioned || []) {
    const found = groups.get(`${s.file}::${s.member}`) || [];
    if (found.length === s.count) {
      for (const h of found) sanctionedHits.push([h, s.why]);
      hits = hits.filter(h => !found.includes(h));
    } else if (found.length === 0) {
      sanctionFailures.push(`STALE SANCTION ${s.file}::${s.member} — no hit left there: delete the entry`);
    } else {
      sanctionFailures.push(`SANCTION COUNT ${s.file}::${s.member} — expects ${s.count}, found ${found.length}: decide each literal again, then set the count`);
    }
  }
  const n = hits.length;
  if (listId) {
    console.log(`[stinks] ${stink.id}: ${n} site(s) (baseline ${baseline})`);
    for (const h of hits) console.log(`    ${h}`);
    if (sanctionedHits.length) {
      console.log(`[stinks] ${stink.id}: ${sanctionedHits.length} sanctioned site(s), not counted:`);
      for (const [h, why] of sanctionedHits) console.log(`    ${h}    -- ${why}`);
    }
    for (const f of sanctionFailures) console.log(`    ${f}`);
    process.exit(0);
  }
  if (sanctionFailures.length) {
    badSanctions += sanctionFailures.length;
    console.error(`[stinks] ${stink.id}: ${sanctionFailures.length === 1 ? '1 sanctioned entry no longer matches its site' : `${sanctionFailures.length} sanctioned entries no longer match their sites`}:`);
    for (const f of sanctionFailures) console.error(`    ${f}`);
  }
  const tag = n > baseline ? 'FAIL' : n < baseline ? 'UNDER' : 'OK';
  console.log(`[stinks] ${stink.id}: ${n} site(s) (baseline ${baseline})${stink.sanctioned ? `, ${sanctionedHits.length} sanctioned` : ''} -- ${tag}`);
  if (n > baseline) {
    over += n - baseline;
    console.error(`    ${stink.why}`);
    for (const h of hits) console.error(`    ${h}`);
  } else if (n < baseline) {
    ratchetable++;
  }
}

if (ratchetable) {
  console.log(`[stinks] NOTE -- ${ratchetable} stink(s) now BELOW baseline; tighten its baseline in buildSystem/check-stinks.js to lock the gain in.`);
}

if (over) {
  console.error(`\n[stinks] FAIL -- ${over} occurrence(s) over baseline. Either fix the smell (preferred) or, if genuinely intentional, raise that stink's baseline in buildSystem/check-stinks.js with a one-line reason.`);
}
if (badSanctions) {
  console.error(`\n[stinks] FAIL -- ${badSanctions} sanctioned entr${badSanctions === 1 ? 'y no longer matches' : 'ies no longer match'} the code it names (see above).`);
}
if (over || badSanctions) process.exit(1);

console.log(`[stinks] OK -- all stinks within baseline.`);
process.exit(0);

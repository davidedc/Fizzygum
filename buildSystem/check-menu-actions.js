#!/usr/bin/env node
// check-menu-actions.js — the MENU-ACTION WIRING gate.
//
// A menu item is dispatched by ButtonWdgt through a FIXED four-slot convention:
//
//     @target[@action].call @target, @, @subjectOfAction, @argumentToAction1, @argumentToAction2
//
// so at every dispatch
//     slot 1 = the MENU ITEM itself      slot 2 = the widget the menu is about      slots 3-4 = arg1/arg2
//
// That convention is invisible at the call site — `menu.addMenuItem "label", target, "verb"` says
// nothing about the four arguments `verb` is going to receive — so it goes wrong in three ways this
// gate makes impossible. All three were LIVE on this tree when the gate was written
// (docs/archive/menu-action-wiring-plan.md).
//
// ── RULE 1 (HARD, sound) — the action must be a STRING method name.
// A function literal in the action slot is provably wrong: the dispatch is `@target[@action]`, so a
// function is coerced to a string key, finds nothing, and throws. ButtonWdgt carries a runtime
// tripwire for it, but a runtime tripwire only fires when something CLICKS, and nothing in the suite
// clicks a slider's "floor..." — three such items sat broken behind that tripwire. A build-time
// check needs no one to click.
// RULE 1 has TWO doors, because there are two ways into a name-dispatched slot. Besides
// addMenuItem/prependMenuItem, `prompt` / `textPrompt` take a `callback` that the prompt's save/Ok
// dispatches by name (`PromptWdgt.deliverValue` / `CodePromptWdgt.deliverValue`:
// `@target[@callback].call @target, @_promptValue()`)
// — the same proof one hop later, so the callbacks count as menu-dispatched verbs for RULE 3 as well.
//
// ── RULE 1b (HARD, sound) — a `@`-targeted STRING action must RESOLVE.
// RULE 1 proves the action slot holds a name; it says nothing about whether anything answers to that
// name. A row wired to a verb nobody implements is dead from the day it is written and stays green
// forever, because the only thing that would notice is a click: `"pin"` on FrameWdgt's own menu was
// dead from 2018 until Plan 1 P1 read it in 2026 (docs/plans/frames-input-touch-program.md, T12).
// The general case is unresolvable — `menu.addMenuItem "…", someExpression, "verb"` has a RECEIVER
// that is a runtime value — but ONE target is knowable at build time: `@`. Inside class C's method,
// `@` is an instance of C or of something that has C in its chain, so the sound resolution set is the
// union of `chainOf(X)` over every X whose chain contains C. That union is what this rule resolves
// against, and a miss is a provable dead row: NO possible receiver implements it.
//   ⚠ The union is what keeps the rule SOUND rather than merely strict. `Widget` itself wires
//   `"setTargetAndActionWithOnesPickedFromMenu"` at `@`, and that verb lives in `ControllerMixin` —
//   only reachable because a `@augmentWith ControllerMixin` class (PaletteWdgt, StringWdgt, …) has
//   `Widget` in its chain. Resolving against the enclosing class ALONE would false-fail there.
//   ⓘ The same union covers a call site inside a MIXIN file for free: `@` in `ControllerMixin`'s own
//   rows is the augmented widget, and every augmenting class has ControllerMixin in its chain.
//   ⓘ The harness is part of the universe: methods a `*TestSupport` class copies onto a core class
//   (`WorldTestSupport.installOnto WorldWdgt`, read from src/boot/globalFunctions.coffee) are real
//   methods of that class on any build shipping the harness part — `WorldWdgt`'s own
//   `"popUpSystemTestsMenu"` row is one. With the sibling tests repo absent this rule therefore
//   SKIPS (rules 1/2/3 still run) rather than false-fail a tests-stripped checkout.
//
// ── RULE 2 (HARD, sound) — the options bag is an object.
// A string literal where `opts` goes is provably wrong for the same reason: `opts.toolTip` on a
// string is undefined.
//
// ── RULE 3 (RATCHET) — an UNREAD parameter on a menu-dispatched verb must be NAMED as unread.
// A verb wired to a menu receives four arguments whether it wants them or not, so authors pad the
// signature to reach the slot they need — `showOutputPins: (a,b,c,d) -> world.pinouts?.show b`. The
// padding is not cosmetic: it puts widgets into parameters whose names promise something else, and
// it forces every OTHER caller to write `w.showOutputPins undefined, w` (a hole, R3 of
// architecture/constructor-and-parameter-conventions.md). The convention this ratchets is the one
// the tree already uses where it is done right — `makeFolderFromMenu: (ignored, ignored2, name, …)`:
// if a slot is there only to be skipped, SAY SO in the name. Anything else must be read.
//
// ⚠ WHAT THIS GATE CANNOT SEE, stated so nobody reads a green run as more than it is: whether a
// parameter that IS read is read as the right THING. `createOpener: (inWhichFolder)` reads its
// parameter and crashed on every click, because from a menu that parameter is a MenuItemWdgt and the
// body did `inWhichFolder.contents.contents`. No text scan can catch that. The mechanism that would
// is a rig that CLICKS every demo menu item — see the plan's residual.
//
// ⚠ AND RULE 3 RESOLVES ACTIONS BY NAME, NOT BY RECEIVER (RULE 1b above is the one receiver-aware
// rule, and only because `@` names its receiver structurally), because the receiver of
// `menu.addMenuItem "…", someExpression, "verb"` is a runtime value and this tree dispatches through
// a string. So a method whose NAME matches a menu action is checked even on a class no menu ever
// wires — `ToggleButtonWdgt.select(whichOne)` is checked because `ListWdgt` wires a `"select"`. That
// direction is deliberate: over-matching costs a spurious rule-3 hit (fix by naming the slot, which
// is never wrong), while under-matching would let a real one through. If it ever false-positives on
// a genuinely unrelated method, prefer renaming that method over loosening the rule.

const fs = require('fs');
const path = require('path');
const { METHOD_HEADER } = require('./lib/coffee-method-header.js');
// The whole-system CLASS MODEL (parent, @augmentWith mixins, methods, resolution order) — RULE 1b's
// engine, reused wholesale rather than re-derived, exactly as census-hierarchy-duplication.js and
// census-property-placement.js reuse it. Re-implementing inheritance resolution here would be a
// second copy of the subtlest part of the tree's static analysis, free to drift.
const { runCensus } = require('./census-public-private-calls.js');

const SRC = path.resolve(__dirname, '../src');
const HARNESS = path.resolve(__dirname, '../../Fizzygum-tests/Automator-and-test-harness-src');
const BOOT_GLOBALS = path.join(SRC, 'boot/globalFunctions.coffee');

// Seeded 2026-08-16 at the count left after the menu-action arc converted the five padded verbs
// (showOutputPins / removeOutputPins / makeFolderWindow / popUpDemoMenu / dockToolbarMenu). The
// survivors are the sanctioned spelling — a slot named for the fact that it is skipped.
const RULE3_BASELINE = 0;

// A parameter name that DECLARES itself unread. `ignored`/`ignored2`/`unused` are the tree's
// existing spelling (PanelWdgt.makeFolderFromMenu, StringWdgt.setFontNameFromMenu).
const DECLARED_UNREAD = /^(ignored|unused)\d*$/;

function walk(dir, acc) {
  if (!fs.existsSync(dir)) return acc;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (e.name.endsWith('.coffee')) acc.push(p);
  }
  return acc;
}
const stripComment = (line) => { const i = line.indexOf('#'); return i < 0 ? line : line.slice(0, i); };

const files = walk(SRC, []);
const hard = [];        // rule 1 + 2 violations
const actionNames = new Set();   // every verb reached from a menu
// RULE 1b's harvest: every row whose TARGET is literally `@`. One class per file, so the enclosing
// class IS the file's basename. { cls, rel, line, action, door, text }
const atTargetSites = [];

// ---- pass 1: read every addMenuItem/prependMenuItem call site -------------------------------
// ⚠ A CALL MAY WRAP, and a scan that reads one line at a time is blind to everything past the
// break — the same blind spot that hid two methods from six gates until lib/coffee-method-header.js
// (see its header). `ListWdgt:90` is the one wrapped call on this tree today and its options object
// is entirely on the continuation lines, so rule 2 would never have looked at it. Continuations are
// simply the deeper-indented lines that follow, joined here before any argument is counted.
function joinContinuation(lines, i) {
  const indent = (lines[i].match(/^\s*/) || [''])[0].length;
  let out = stripComment(lines[i]);
  for (let j = i + 1; j < lines.length; j++) {
    const nxt = lines[j];
    if (!nxt.trim()) break;
    if ((nxt.match(/^\s*/) || [''])[0].length <= indent) break;
    out += ' ' + stripComment(nxt).trim();
  }
  return out;
}

for (const p of files) {
  const rel = path.relative(SRC, p);
  const cls = path.basename(p, '.coffee');
  const allLines = fs.readFileSync(p, 'utf8').split('\n');
  // ---- RULE 1, second door: prompt / textPrompt -------------------------------------------
  // `prompt: (msg, target, callback, opts = {})` does not dispatch the callback itself — the prompt's
  // save/Ok does, by name (`PromptWdgt.deliverValue` / `CodePromptWdgt.deliverValue`:
  // `@target[@callback].call @target, @_promptValue()`),
  // so the callback slot IS an action slot and a function literal there is wrong for exactly the same
  // reason, one hop later. Same proof, same severity, so it lives here rather than in its own gate.
  // ⓘ Deliberately NOT the stricter "the 3rd argument must be a string LITERAL": that would flag a
  // variable holding a method name, which is legitimate and which RULE 1 already tolerates for
  // addMenuItem. Keeping both doors to the same standard is what keeps this gate a sound negative.
  allLines.forEach((raw, i) => {
    // keyed on the RECEIVER (`@prompt …` / `@element.prompt …`), which is what tells a CALL apart
    // from the definition `prompt: (msg, target, callback, opts = {}) ->`. ⚠ An earlier spelling
    // keyed on the first ARGUMENT instead and matched only quoted/`@` first args, so it silently
    // missed every real site — all of which open with an expression (`menuItem.parent.title + …`).
    if (!/[@.](?:textPrompt|prompt)\s+\S/.test(stripComment(raw))) return;
    const m = /[@.](?:textPrompt|prompt)\s+(.*)$/.exec(joinContinuation(allLines, i));
    if (!m) return;
    const parts = splitTopLevel(m[1]);
    if (parts.length < 3) return;
    const cb = parts[2].trim();
    if (/^\(?\s*(?:\(|->|=>)/.test(cb)) {
      hard.push({ rel, line: i + 1, rule: 1, text: raw.trim(),
        why: 'a FUNCTION LITERAL in the prompt CALLBACK slot — the prompt\'s Ok dispatches it as `@target[@callback]` (PromptWdgt.deliverValue), so this throws on Ok' });
      return;
    }
    // a prompt callback is a menu-dispatched verb like any other: let RULE 3 see it too
    const nm = /^["']([A-Za-z_]\w*)["']$/.exec(cb);
    if (nm) {
      actionNames.add(nm[1]);
      if (parts[1].trim() === '@') atTargetSites.push({ cls, rel, line: i + 1, action: nm[1], door: 'prompt callback', text: raw.trim() });
    }
  });
  allLines.forEach((raw, i) => {
    if (!/\b(?:add|prepend)MenuItem\b/.test(stripComment(raw))) return;
    const line = joinContinuation(allLines, i);
    const m = /\b(?:add|prepend)MenuItem\s+(.*)$/.exec(line);
    if (!m) return;
    const args = m[1];
    // the action is the 3rd argument; find it by splitting on top-level commas
    const parts = splitTopLevel(args);
    if (parts.length < 3) return;
    const action = parts[2].trim();

    if (/^\(?\s*(?:\(|->|=>)/.test(action)) {
      hard.push({ rel, line: i + 1, rule: 1, text: raw.trim(),
        why: 'a FUNCTION LITERAL in the action slot — dispatch is `@target[@action]`, so this throws when clicked' });
      return;
    }
    const nameMatch = /^["']([A-Za-z_]\w*)["']$/.exec(action);
    if (nameMatch) {
      actionNames.add(nameMatch[1]);
      if (parts[1].trim() === '@') atTargetSites.push({ cls, rel, line: i + 1, action: nameMatch[1], door: 'menu row', text: raw.trim() });
    }

    if (parts.length >= 4) {
      const opts = parts[3].trim();
      if (/^["']/.test(opts) && !/:/.test(opts)) {
        hard.push({ rel, line: i + 1, rule: 2, text: raw.trim(),
          why: 'a STRING LITERAL where the options object goes — `opts.toolTip` on a string is undefined' });
      }
    }
  });
}

// Split an argument list on commas that are not inside (), [], {} or a string.
function splitTopLevel(s) {
  const out = []; let depth = 0, quote = null, cur = '';
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (quote) { if (c === quote && s[i - 1] !== '\\') quote = null; cur += c; continue; }
    if (c === '"' || c === "'") { quote = c; cur += c; continue; }
    if (c === '(' || c === '[' || c === '{') depth++;
    if (c === ')' || c === ']' || c === '}') depth--;
    if (c === ',' && depth === 0) { out.push(cur); cur = ''; continue; }
    cur += c;
  }
  if (cur.trim()) out.push(cur);
  return out;
}

// ---- pass 2: for each menu-reached verb, find its definition and check its parameters --------
const unread = [];
for (const p of files) {
  const rel = path.relative(SRC, p);
  const lines = fs.readFileSync(p, 'utf8').split('\n');
  for (let i = 0; i < lines.length; i++) {
    const h = METHOD_HEADER.exec(lines[i]);
    if (!h) continue;
    const name = h[1];
    if (!actionNames.has(name)) continue;

    const sig = /\(([^)]*)\)/.exec(lines[i]);
    if (!sig) continue;
    const params = sig[1].split(',').map(s => s.trim()).filter(Boolean)
      .map(s => s.replace(/\s*=.*$/, '').replace(/^@/, ''));
    if (!params.length) continue;

    // body = lines until the next method header at the same indent (or EOF)
    let body = '';
    for (let j = i + 1; j < lines.length; j++) {
      if (METHOD_HEADER.test(lines[j])) break;
      body += stripComment(lines[j]) + '\n';
    }
    for (const prm of params) {
      if (DECLARED_UNREAD.test(prm)) continue;
      if (new RegExp(`\\b${prm}\\b`).test(body)) continue;
      unread.push({ rel, line: i + 1, name, prm, text: lines[i].trim() });
    }
  }
}

// ---- pass 3 (RULE 1b): every `@`-targeted string action must resolve on a possible receiver -----
// The resolution set for `@` inside class C is the union of `chainOf(X)` over every X whose chain
// CONTAINS C — that is, C itself, every subclass of C, and every class that `@augmentWith`es C (the
// census's chainOf already folds both edges into one order). A verb missing from all of them is
// dispatched at nothing: `@target[@action]` is undefined and the row throws on click.
let ruleB = { checked: 0, skipped: '' };
if (!fs.existsSync(HARNESS)) {
  // Methods a `*TestSupport` class installs onto a core class are real methods of that class
  // wherever the harness part ships, so without the sibling repo the universe is incomplete and a
  // miss would not be a proof. Same self-skip as check-dead-methods / check-unresolved-sends.
  ruleB.skipped = 'sibling Fizzygum-tests not present (its *TestSupport installs are part of the resolution universe)';
} else {
  const census = runCensus();
  const { classInfo, chainOf } = census;

  // harness methods installed onto a core class, read from the ACTUAL boot edges
  // (`WorldTestSupport.installOnto WorldWdgt` & co in src/boot/globalFunctions.coffee).
  const installedOn = new Map();   // core class name -> Set(method names)
  if (fs.existsSync(BOOT_GLOBALS)) {
    const bootText = fs.readFileSync(BOOT_GLOBALS, 'utf8');
    const EDGE = /\b([A-Za-z_]\w*)\.installOnto\s+([A-Za-z_]\w*)/g;
    let e;
    while ((e = EDGE.exec(bootText)) !== null) {
      const supportFile = path.join(HARNESS, e[1] + '.coffee');
      if (!fs.existsSync(supportFile)) continue;
      if (!installedOn.has(e[2])) installedOn.set(e[2], new Set());
      const into = installedOn.get(e[2]);
      for (const l of fs.readFileSync(supportFile, 'utf8').split('\n')) {
        const h = METHOD_HEADER.exec(l);
        if (h) into.add(h[1]);
      }
    }
  }

  // C -> every class whose chain contains C (i.e. every class an `@` in C could be an instance of)
  const receiversOf = new Map();
  for (const name of classInfo.keys()) {
    for (const info of chainOf(name)) {
      if (!receiversOf.has(info.name)) receiversOf.set(info.name, new Set());
      receiversOf.get(info.name).add(name);
    }
  }
  const definesIt = (clsName, action) => {
    for (const info of chainOf(clsName)) {
      if (info.methods.has(action)) return true;
      const inst = installedOn.get(info.name);
      if (inst && inst.has(action)) return true;
    }
    return false;
  };

  for (const s of atTargetSites) {
    if (!classInfo.has(s.cls)) continue;          // not a class file — `@` is not an instance
    ruleB.checked++;
    let found = false;
    for (const receiver of (receiversOf.get(s.cls) || [s.cls])) {
      if (definesIt(receiver, s.action)) { found = true; break; }
    }
    if (found) continue;
    hard.push({ rel: s.rel, line: s.line, rule: '1b', text: s.text,
      why: `the ${s.door} targets \`@\` with action "${s.action}", and NO class that \`@\` could be here — ${s.cls}, its subclasses, its mixin consumers, their chains — defines it, so \`@target[@action]\` is undefined and the row throws when clicked` });
  }
}

let bad = 0;
for (const h of hard) {
  console.error(`[menu-actions] RULE ${h.rule} FAIL — ${h.rel}:${h.line}`);
  console.error(`    ${h.text}`);
  console.error(`    ${h.why}`);
  bad++;
}
for (const u of unread) {
  console.log(`  ${u.rel}:${u.line}  ${u.name}  unread parameter \`${u.prm}\``);
}

if (ruleB.skipped) console.log(`[menu-actions] RULE 1b SKIP — ${ruleB.skipped}.`);

if (bad) {
  console.error(`\n[menu-actions] FAIL — ${bad} provably-wrong menu wiring(s).`);
  console.error('An action must be a STRING method name on the target that SOMETHING implements, and');
  console.error('the 4th argument is the options object.');
  console.error('Law: docs/architecture/constructor-and-parameter-conventions.md');
  process.exit(1);
}
if (unread.length > RULE3_BASELINE) {
  console.error(`\n[menu-actions] FAIL — ${unread.length} unread menu-action parameter(s), baseline ${RULE3_BASELINE}.`);
  console.error('A verb wired to a menu receives four dispatcher slots whether it wants them or not.');
  console.error('If a slot exists only to be skipped, NAME it so: `ignored`, `ignored2`, `unused`.');
  console.error('Otherwise read it — or drop it, and let the dispatcher\'s extra arguments fall away.');
  process.exit(1);
}
if (unread.length < RULE3_BASELINE) {
  console.log(`\n[menu-actions] ${unread.length} unread parameter(s) (baseline ${RULE3_BASELINE}) -- UNDER`);
  console.log(`NOTE: tighten RULE3_BASELINE to ${unread.length} in buildSystem/check-menu-actions.js, in THIS commit.`);
} else {
  console.log(`\n[menu-actions] OK — ${actionNames.size} menu-dispatched verb(s); ${ruleB.checked} \`@\`-targeted row(s) all resolve; 0 provably-wrong wirings; ${unread.length} unread parameter(s) (baseline ${RULE3_BASELINE}).`);
}

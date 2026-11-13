#!/usr/bin/env node
'use strict';
// check-unresolved-sends.js — build gate: flag CALLS whose name nobody IMPLEMENTS.
//
// The exact INVERSE of check-dead-methods.js (which catches defined-but-never-sent; this catches
// sent-but-never-defined). A call-shaped reference `[@.]name(` whose `name` is defined nowhere in
// the shipped universe is a guaranteed runtime TypeError on any path that reaches it. Pharo
// ancestry: ReSentNotImplementedRule.
//
// UNIVERSE = the compiled sources (lib/source-files.js compiledFiles: src/ and the sibling tests repo's harness,
// Fizzygum-tests/Automator-and-test-harness-src/ — harness code is LIVE code: it is
// compiled into every non-homepage build, and src calls into it behind `if Automator?` guards).
// Its CALLS are also read from every MACRO SOURCE (lib/macro-sources.js: the CoffeeScript alone, as the page compiles
// it — each test's, never the JS around it, and each verb's, a `Macro.fromString` literal of src or the harness, which
// a reading of the file's own code sees only as a string), because a macro calls core methods as directly as the
// harness does: a rename that misses a macro's `.name(` fails here, at build time, instead of in the suite. A macro's
// own definitions (a local helper, an object of handlers) resolve that macro's own calls and no one else's, so they
// never widen the shared universe.
// The harness is half the definition universe, so the sibling tests repo is read on every build whatever the profile
// ships (the build requires it; lib/source-files.js sourceRoots refuses a hand run without it).
//
// ── THE SOUNDNESS TRADE (read before "tightening" anything here) ────────────────────────────────
// This gate is deliberately built to have ZERO false positives at the cost of detection reach — a
// false FAIL breaks the build on correct code, while a miss merely leaves a fault for the boot
// smoke / SystemTests to catch. Same philosophy as the rejected transitive-[G] closure
// (docs/archive/lint-ratchet-static-checks-plan.md): soundness beats reach. That trade is implemented as a
// deliberate ASYMMETRY in which reading of each source (lib/coffee-mask.js) the two sides take — both err toward
// "fewer flags":
//
//   DEFS  are the CALLABLE definitions (lib/name-definitions.js: a method header, a prototype
//         extension, an expando or a top-level function — a data key or an indented local defines
//         nothing), read off each line's CODE (comment blanked, literals KEPT): a heredoc holds code
//         that defines names (MacroToolkit's verbs), so a def "found" inside a string only ever ADDS
//         to the implementor set → fewer flags.
//   CALLS are read off each line's BARE code (comments and literal contents blanked, an
//         interpolation's code kept — a method called ONLY as "…#{@foo()}…" is a genuine send), so a
//         call-shaped token inside a string or comment can never be flagged.
//
// KNOWN GAPS (accepted; each is a reach limit, never a false-fail source):
//   - PAREN-CALLS ONLY. CoffeeScript's paren-less `@foo arg` is not harvested — too noisy to gate
//     on (a bare `@foo bar` is textually indistinguishable from a property read + expression).
//   - STRING-DISPATCHED sends are invisible. Menu/button actions dispatch by string method name;
//     closing that hole needs an action-string checker (plan §8.1).
//   - Capital-initial names are skipped: `new Foo(`-adjacent class references are the boot
//     dependency finder's jurisdiction (src/boot/dependencies-finding.coffee).
//   - No receiver typing: a name defined ANYWHERE resolves a call EVERYWHERE. Hierarchy-resolved
//     `@`-self sends are a v2 item (plan §8.7). The one receiver the gate reads is a literal
//     identifier right against the dot, and only to match a KEYED BUILTINS entry (`Math.round`) — by
//     NAME, so a local that borrows a platform global's name (`console = @parent…`) reads as it.
//     ⚠ The one bounded exception to "never a false fail": once EVERY Fizzygum definition of a keyed
//     name is deleted, a platform call of it whose receiver the gate cannot read (`window.Math.round(`,
//     none today) fails beside the real ones. While any definition exists, every call resolves through it.
//   - A property that HOLDS a closure is no definition, so a call of one (`drawFunction`) resolves
//     only through its allowlist entry, which says so.
//
// EXEMPTIONS — two lists:
//   BUILTINS (in-file, below)              — JS/DOM/canvas platform API. A fact about the platform:
//                                            BARE (`push`) by default, KEYED by receiver
//                                            (`Math.round`) for a name Fizzygum also defines that
//                                            only a platform global sends.
//   unresolved-sends-allowlist.txt (file)  — vendor + genuinely-dynamic names, `name  # reason`.
//                                            A fact about Fizzygum's dependencies. An entry with no
//                                            unresolved call left FAILS as stale (STALE_ALLOWLIST_ENTRY).
//
// Exit codes: 0 clean · 1 unresolved send not exempted · 2 operational error.
// Flags: --update-allowlist (re-seed the allowlist with the current unresolved set)
// Its in-memory fixtures for both harvests are check-unresolved-sends-selftest.js.

const fs = require('fs');
const path = require('path');
// The DEF side — its DEF_FORMS, the harvest — is the shared lib/name-definitions.js, which check-part-edges.js reads
// too: one implementor harvest, not two.
const defs = require('./lib/name-definitions.js');
const { coffeeMask } = require('./lib/coffee-mask');
const { readAllowlist } = require('./lib/allowlist-file');
const { rejectUnknownArgs, rejectPositionalArgs } = require('./lib/cli-args');
const { compiledFiles, sourceRoots, sourceName, SOURCE_RAILS } = require('./lib/source-files');
const rules = require('./lib/gate-rules').forGate(__filename);
// bite-unplantable: BUILTINS_KEYED_OFF_PLATFORM — both sides are this file's own constants (BUILTINS_TABLE, PLATFORM_GLOBALS); a planted src tree reaches neither

// Run from the Fizzygum/ repo root (build_it_please.sh does): node ./buildSystem/check-unresolved-sends.js [--src=DIR]
// [--tests-repo=DIR] — the rails read another src tree or tests repo (a copy carrying a plant); the tests repo's
// harness and macros are read from the one given. That every rule BITES — a send left with no callable definition,
// among them one whose name survives only as a data key, and each way an exemption table goes stale or takes the
// wrong form — is proven on every build by check-unresolved-sends-selftest.js.
let ROOTS;   // main() reads the rails
const { macroSources } = require('./lib/tests-repo-code');
const { verbMacroSourcesIn } = require('./lib/macro-sources');
const ALLOWLIST = path.resolve(__dirname, 'unresolved-sends-allowlist.txt');

// ─── reading ───────────────────────────────────────────────────────────────────────────────────
// Each file is read through lib/coffee-mask.js once for both harvests (kept by path, for the text it had).
const readings = new Map();   // path -> { text, masked }
const readingOf = (p) => {
  const text = fs.readFileSync(p, 'utf8');
  if (!readings.has(p) || readings.get(p).text !== text) readings.set(p, { text, masked: coffeeMask(text, p) });
  return readings.get(p).masked;
};

// ─── the implementors ("defs") harvest ──────────────────────────────────────────────────────────
// The forms (and why each is there) live in lib/name-definitions.js's DEF_FORMS; this reads files.
function harvestDefs(files) {
  const defined = new Set();
  for (const p of files) defs.harvestDefs(readingOf(p), defined);
  return defined;
}

// ─── the senders ("calls") harvest ──────────────────────────────────────────────────────────────
const CALL_RE = /([@.])([A-Za-z_$][\w$]*)\(/g;   // group 1 = the receiver sigil, kept so the report can echo the real call shape
// The RECEIVER of a `.name(` call, when it is a bare identifier written right against the dot
// (`Math.round(`, `x = JSON.parse(`): a literal name, never an expression (`@a.round(`, `a.b.round(`,
// `(x).round(`, `Math .round(` and a string ending in an interpolation have none). A keyed BUILTINS
// entry is matched against it.
const RECEIVER_RE = /(?:^|[^\w$@.\])])([A-Za-z_$][\w$]*)$/;
function literalReceiver(code, dotIndex) {
  const m = code.slice(0, dotIndex).match(RECEIVER_RE);
  return m ? m[1] : undefined;
}

// label a path for the report: src/<file>, or harness/<file> (lib/source-files.js sourceName)
const label = (p) => sourceName(p, ROOTS, 'src/');

// A macro's sends: each macro source of a file (a test's command file, a .coffee file's verbs), read as CoffeeScript
// exactly as harvestCalls reads a .coffee file. Every site carries its file's macro sources' OWN definitions (`local`).
function sendsOfMacroSources(sources, where, at) {
  const sites = [];
  const local = new Set();
  const masked = sources.map((src) => coffeeMask(src.text, `${where} (its macro source from line ${src.line})`));
  for (const m of masked) defs.harvestDefs(m, local);
  sources.forEach((src, k) => {
    const raws = src.text.split('\n');
    masked[k].forEach(({ bare: code }, i) => {
      let m;
      CALL_RE.lastIndex = 0;
      while ((m = CALL_RE.exec(code)) !== null) {
        if (/^[A-Z]/.test(m[2])) continue;
        const recv = m[1] === '.' ? literalReceiver(code, m.index) : undefined;
        sites.push({ name: m[2], sigil: m[1], recv, local, at: `${at}:${src.line + i}`, text: raws[i].trim().slice(0, 110) });
      }
    });
  });
  return sites;
}
function harvestMacroCalls(files) {
  const sites = [];
  for (const { file, sources } of macroSources(ROOTS.testsRepo)) sites.push(...sendsOfMacroSources(sources, file, path.relative(ROOTS.testsRepo, file)));
  for (const p of files) sites.push(...sendsOfMacroSources(verbMacroSourcesIn(fs.readFileSync(p, 'utf8'), p), p, label(p)));
  return sites;
}

function harvestCalls(files) {
  const sites = [];   // { name, at, text }
  for (const p of files) {
    const raws = fs.readFileSync(p, 'utf8').split('\n');
    readingOf(p).forEach(({ bare: code }, i) => {
      let m;
      CALL_RE.lastIndex = 0;
      while ((m = CALL_RE.exec(code)) !== null) {
        if (/^[A-Z]/.test(m[2])) continue;   // class-ish reference — the dependency finder's jurisdiction
        const recv = m[1] === '.' ? literalReceiver(code, m.index) : undefined;
        sites.push({ name: m[2], sigil: m[1], recv, at: `${label(p)}:${i + 1}`, text: raws[i].trim().slice(0, 110) });
      }
    });
  }
  return sites;
}

// ─── the platform (JS / DOM / canvas builtins) ──────────────────────────────────────────────────
// A fact about the PLATFORM, not about Fizzygum — hence in-file, not in the allowlist. Each entry is a
// platform method some `[@.]name(` call in src+harness SENDS, in one of two forms:
//   BARE   `name` — excuses EVERY call of the name. The default: the gate cannot type an instance (an
//          Array's `push`, a canvas context's `save`, a Map's `get`).
//   KEYED  `Recv.name` — for a name Fizzygum ALSO defines that only a platform global sends
//          (`Math.round` beside `Point::round`). It excuses a call only when the receiver written right
//          before the dot is that global, so once every Fizzygum `round` is deleted, a surviving
//          `@bounds.round(` FAILS instead of being excused as platform API. Keying is for unmasking:
//          while Fizzygum defines the name, every call of it resolves through that definition, so a
//          receiver the gate cannot read (`window.Math.round(`) can never false-fail.
// The form is held to the sends both ways: a bare name Fizzygum also defines, which every call sends to
// a PLATFORM_GLOBALS receiver, fails until it is keyed (BUILTINS_NOT_KEYED); a keyed name Fizzygum no
// longer defines, with no unresolved call of it left, has nothing to unmask and goes back to bare
// (BUILTINS_KEYED_NOTHING_TO_UNMASK); a keyed receiver must be a PLATFORM_GLOBALS name
// (BUILTINS_KEYED_OFF_PLATFORM); and an entry no call sends — bare, or keyed with no `Recv.name(` — fails
// as stale (STALE_ALLOWLIST_ENTRY). Stale is not harmless: it excuses nothing today, yet once Fizzygum
// defines and calls a method of that name, deleting the method while a call survives would be excused
// by the entry — the guaranteed TypeError this gate exists to catch.
// ⚠ A BARE name Fizzygum also defines (`save`, `get`, `clear`, `fill`, `toString`, …) still masks the
// deletion of every Fizzygum implementor of it; listing it is still right, because the platform call
// is real.
const BUILTINS_TABLE = `
push pop shift slice concat join filter map some every indexOf lastIndexOf includes sort reverse fill keys values
charAt charCodeAt fromCharCode toLowerCase toUpperCase trim trimEnd split replace match search padStart repeat substring substr
toString toFixed valueOf
sqrt pow random atan2 sin cos asin exp log sign
now parse stringify
getContext measureText beginPath closePath stroke clip save restore translate scale setTransform drawImage getImageData createPattern
preventDefault appendChild createElement getElementById getElementsByTagName querySelectorAll focus blur click
then resolve all call test exec toDataURL
has get clear
open
isInteger isFinite isView from
getTime getHours getMinutes getSeconds getMilliseconds
Math.abs Math.floor Math.ceil Math.round Math.min Math.max Array.isArray
`.trim().split(/\s+/);
const BUILTINS = new Set(BUILTINS_TABLE.filter((e) => !e.includes('.')));          // bare: any receiver
const BUILTINS_KEYED = new Set(BUILTINS_TABLE.filter((e) => e.includes('.')));    // `Recv.name`: that receiver only
// The platform's own globals, as a call's literal receiver: what a keyed entry may name, and what makes a
// bare shared name "only ever sent to the platform". A fact about the platform; an entry no BUILTINS
// call is sent to fails as stale, and one naming a Fizzygum class fails outright.
const PLATFORM_GLOBALS = new Set(`
Math Object Array ArrayBuffer Number String JSON Date Promise performance document window
`.trim().split(/\s+/));

// ─── run ────────────────────────────────────────────────────────────────────────────────────────
function main() {
  const argv = process.argv.slice(2);
  rejectUnknownArgs(argv, ['--update-allowlist', ...SOURCE_RAILS], 'unresolved-sends');
  rejectPositionalArgs(argv, 'unresolved-sends', 'a src tree is named with --src=DIR');
  ROOTS = sourceRoots(argv, 'unresolved-sends');
  if (argv.includes('--update-allowlist') && argv.some((a) => SOURCE_RAILS.some((r) => a.startsWith(r)))) {
    console.error('[unresolved-sends] ERROR — --update-allowlist writes the real allowlist: it never reads another src tree or tests repo');
    process.exit(2);
  }
  if (!fs.existsSync(ROOTS.src)) {
    console.error('[unresolved-sends] ERROR — cannot find src/ — run from the Fizzygum repo root.');
    process.exit(2);
  }
  const files = compiledFiles(ROOTS);
  const defined = harvestDefs(files);
  const sites = [...harvestCalls(files), ...harvestMacroCalls(files)];

  const allow = readAllowlist(ALLOWLIST);   // name -> reason

  // name -> sites, for every call that resolves to nothing we know about
  const unresolved = new Map();
  const builtinExcuses = (s) => BUILTINS.has(s.name) || (s.recv !== undefined && BUILTINS_KEYED.has(s.recv + '.' + s.name));
  for (const s of sites) {
    if (defined.has(s.name) || (s.local && s.local.has(s.name)) || builtinExcuses(s)) continue;
    if (!unresolved.has(s.name)) unresolved.set(s.name, []);
    unresolved.get(s.name).push(s);
  }

  if (process.argv.includes('--update-allowlist')) {
    const names = [...unresolved.keys()].sort();
    const header =
      '# Unresolved-sends allowlist for buildSystem/check-unresolved-sends.js\n' +
      '# Names CALLED as `[@.]name(` in src/harness but implemented nowhere in either — i.e. vendor\n' +
      '# APIs and genuinely-dynamic sends. Platform (JS/DOM/canvas) names do NOT belong here: they\n' +
      '# live in the in-file BUILTINS set. Format: `name  # reason` (the reason is the point).\n' +
      '# The gate FAILS on any unresolved send not listed here, and on an entry no unresolved call needs.\n\n';
    fs.writeFileSync(ALLOWLIST, header + names.map((n) => `${n}  # TODO: reason`).join('\n') + '\n');
    console.log(`[unresolved-sends] wrote ${names.length} name(s) to ${path.relative(process.cwd(), ALLOWLIST)}`);
    process.exit(0);
  }

  const violations = [...unresolved.keys()].filter((n) => !allow.has(n)).sort();
  // A STALE allowlist entry — a name with no unresolved call left — excuses nothing today and would excuse the
  // next call of that name that nobody implements, so it FAILS (STALE_ALLOWLIST_ENTRY), saying which way it went.
  // A BUILTINS entry is held to the same rule: one no call sends is stale (see BUILTINS), and so is its FORM.
  const sent = new Set(sites.map((s) => s.name));
  const sentKeyed = new Set(sites.filter((s) => s.recv !== undefined).map((s) => s.recv + '.' + s.name));
  const unsentBuiltins = [...BUILTINS].filter((n) => !sent.has(n))
    .map((n) => `BUILTINS ${n} — no \`[@.]${n}(\` call in src, the harness or a macro sends it`)
    .concat([...BUILTINS_KEYED].filter((e) => !sentKeyed.has(e))
      .map((e) => `BUILTINS ${e} — no \`${e}(\` call in src, the harness or a macro sends it`));
  const sentToGlobal = new Set(sites.filter((s) => s.recv !== undefined && PLATFORM_GLOBALS.has(s.recv) && builtinExcuses(s)).map((s) => s.recv));
  const staleGlobals = [...PLATFORM_GLOBALS].filter((g) => !sentToGlobal.has(g));
  const classNames = new Set(files.map((p) => path.basename(p, '.coffee')));
  const keyName = (e) => e.slice(e.indexOf('.') + 1), keyReceiver = (e) => e.slice(0, e.indexOf('.'));
  // a bare name Fizzygum also defines, which only platform globals send, masks Fizzygum's implementors of it
  const unkeyed = [...BUILTINS].filter((n) => defined.has(n) && sent.has(n) &&
    sites.every((s) => s.name !== n || (s.recv !== undefined && PLATFORM_GLOBALS.has(s.recv))));
  // a keyed name Fizzygum does not define unmasks nothing (and a receiver the gate cannot read would
  // false-fail): once no call of it is left unresolved it goes back to bare
  const nothingToUnmask = [...BUILTINS_KEYED].filter((e) => !defined.has(keyName(e)) && !unresolved.has(keyName(e)));
  const formErrors = unkeyed.map((n) => rules.fired('BUILTINS_NOT_KEYED', `BUILTINS_NOT_KEYED ${n} — Fizzygum defines ${n}, and every \`.${n}(\` call sends it to a platform global (` +
      [...new Set(sites.filter((s) => s.name === n).map((s) => s.recv))].join(', ') + `): list it keyed, as Recv.${n}, so it excuses only those`))
    .concat(nothingToUnmask.map((e) => rules.fired('BUILTINS_KEYED_NOTHING_TO_UNMASK', `BUILTINS_KEYED_NOTHING_TO_UNMASK ${e} — no definition of ${keyName(e)} is in src+harness: list it bare`)))
    .concat([...BUILTINS_KEYED].filter((e) => !PLATFORM_GLOBALS.has(keyReceiver(e)))
      .map((e) => rules.fired('BUILTINS_KEYED_OFF_PLATFORM', `BUILTINS_KEYED_OFF_PLATFORM ${e} — ${keyReceiver(e)} is not one of PLATFORM_GLOBALS`)))
    .concat([...PLATFORM_GLOBALS].filter((g) => classNames.has(g))
      .map((g) => rules.fired('PLATFORM_GLOBALS_NAMES_FIZZYGUM', `PLATFORM_GLOBALS_NAMES_FIZZYGUM ${g} — ${g} is a Fizzygum class: its methods are Fizzygum's to define, not the platform's`)))
    .concat(staleGlobals.map((g) => rules.fired('STALE_PLATFORM_GLOBAL', `STALE_ALLOWLIST_ENTRY PLATFORM_GLOBALS ${g} — no BUILTINS call in src, the harness or a macro is sent to ${g}`)));
  const stale = [...allow.keys()].filter((n) => !unresolved.has(n)).sort().map((n) =>
    `${n} — ${!sent.has(n) ? 'no `[@.]' + n + '(` call is left in src, the harness or a macro'
      : defined.has(n) ? 'it resolves: a definition of it is in src+harness'
      : 'it is a BUILTINS name'}`);

  if (stale.length) {
    console.error(`\n[unresolved-sends] FAIL — ${stale.length} stale entr${stale.length === 1 ? 'y' : 'ies'} in buildSystem/unresolved-sends-allowlist.txt (delete each):`);
    for (const s of stale) console.error(rules.fired('STALE_ALLOWLIST_ENTRY', `  STALE_ALLOWLIST_ENTRY ${s}`));
  }
  if (unsentBuiltins.length) {
    console.error(`\n[unresolved-sends] FAIL — ${unsentBuiltins.length} BUILTINS entr${unsentBuiltins.length === 1 ? 'y' : 'ies'} in check-unresolved-sends.js that no call sends (delete each):`);
    for (const s of unsentBuiltins) console.error(rules.fired('STALE_BUILTIN', `  STALE_ALLOWLIST_ENTRY ${s}, so it would only excuse the deletion of a future same-named Fizzygum method`));
  }
  if (formErrors.length) {
    console.error(`\n[unresolved-sends] FAIL — ${formErrors.length} BUILTINS entr${formErrors.length === 1 ? 'y' : 'ies'} in check-unresolved-sends.js in the wrong form:`);
    for (const e of formErrors) console.error(`  ${e}`);
  }

  if (violations.length) {
    const n = violations.reduce((a, v) => a + unresolved.get(v).length, 0);
    console.error(`\n[unresolved-sends] FAIL — ${n} call site(s) across ${violations.length} name(s) with no definition in src+harness (or, for a macro, in its own source):`);
    for (const name of violations) {
      for (const s of unresolved.get(name)) {
        console.error(rules.fired('UNRESOLVED_SEND', `  ${s.at}: ${s.sigil}${name}( — no definition found in src+harness${s.local ? ' or in its own macro source' : ''}`));
        console.error(`      ${s.text}`);
      }
    }
    console.error('\nEither FIX the call (a name nobody implements is a runtime TypeError on any path that reaches it),');
    console.error('or — if it is a vendor API / a genuinely dynamic send — add its name to');
    console.error('buildSystem/unresolved-sends-allowlist.txt with a reason. (Standard JS/DOM/canvas API goes in');
    console.error('the BUILTINS set inside check-unresolved-sends.js instead.)');
    process.exit(1);
  }
  if (stale.length || unsentBuiltins.length || formErrors.length) process.exit(1);

  console.log(`[unresolved-sends] OK — ${sites.length} calls checked, 0 unresolved (${defined.size} names implemented, ${allow.size} allowlisted; BUILTINS ${BUILTINS.size} bare + ${BUILTINS_KEYED.size} keyed).`);
  process.exit(0);
}

module.exports = { harvestDefs, harvestCalls };

if (require.main === module) main();

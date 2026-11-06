#!/usr/bin/env node
'use strict';
// check-unresolved-sends.js — build gate: flag CALLS whose name nobody IMPLEMENTS.
//
// The exact INVERSE of check-dead-methods.js (which catches defined-but-never-sent; this catches
// sent-but-never-defined). A call-shaped reference `[@.]name(` whose `name` is defined nowhere in
// the shipped universe is a guaranteed runtime TypeError on any path that reaches it. Pharo
// ancestry: ReSentNotImplementedRule.
//
// UNIVERSE = src/**/*.coffee + the sibling test harness
// (Fizzygum-tests/Automator-and-test-harness-src/**/*.coffee — harness code is LIVE code: it is
// compiled into every non-homepage build, and src calls into it behind `if Automator?` guards).
// Like check-dead-methods, this SKIPS (exit 0 + a loud note) when the sibling tests repo is absent,
// rather than false-fail a tests-stripped checkout.
//
// ── THE SOUNDNESS TRADE (read before "tightening" anything here) ────────────────────────────────
// This gate is deliberately built to have ZERO false positives at the cost of detection reach — a
// false FAIL breaks the build on correct code, while a miss merely leaves a fault for the boot
// smoke / SystemTests to catch. Same philosophy as the rejected transitive-[G] closure
// (docs/archive/lint-ratchet-static-checks-plan.md): soundness beats reach. That trade is implemented as a
// deliberate ASYMMETRY in how the two sides are masked — both err toward "fewer flags":
//
//   DEFS  are OVER-approximated: harvested with a naive (`#{`-aware) comment strip that KEEPS
//         string literals, and the last DEF_FORM counts ANY `name:`/`name =` key as a definition
//         (a property may hold a closure that gets called). A def "found" inside a string only ever
//         ADDS to the implementor set → fewer flags. Keeping the naive strip here also immunizes
//         the def harvest from stripLine's known bogus-heredoc state: `TRIPLE_QUOTES = ///'''///`
//         (src/boot/dependencies-finding.coffee:59) is a BLOCK REGEX whose `'''` reads to stripLine
//         as an unterminated heredoc, blanking the rest of that file. Blanked DEFS would cause
//         FALSE POSITIVES; blanked CALLS only cost coverage.
//   CALLS are UNDER-approximated: harvested with the stripLine-grade masker below (comments AND
//         string literals removed, multi-line state carried), so a call-shaped token inside a
//         string or comment can never be flagged.
//
// KNOWN GAPS (accepted; each is a reach limit, never a false-fail source):
//   - PAREN-CALLS ONLY. CoffeeScript's paren-less `@foo arg` is not harvested — too noisy to gate
//     on (a bare `@foo bar` is textually indistinguishable from a property read + expression).
//   - STRING-DISPATCHED sends are invisible. Menu/button actions dispatch by string method name;
//     closing that hole needs an action-string checker (plan §8.1).
//   - Capital-initial names are skipped: `new Foo(`-adjacent class references are the boot
//     dependency finder's jurisdiction (src/boot/dependencies-finding.coffee).
//   - The macro test .js files are NOT scanned (their template-literal bodies produce JS-side false
//     positives; the macro surface is already policed by check-layering rule [D]).
//   - No receiver typing: a name defined ANYWHERE resolves a call EVERYWHERE. Hierarchy-resolved
//     `@`-self sends are a v2 item (plan §8.7). The one receiver the gate reads is a literal
//     identifier right against the dot, and only to match a KEYED BUILTINS entry (`Math.round`) — by
//     NAME, so a local that borrows a platform global's name (`console = @parent…`) reads as it.
//     ⚠ The one bounded exception to "never a false fail": once EVERY Fizzygum definition of a keyed
//     name is deleted, a platform call of it whose receiver the gate cannot read (`window.Math.round(`,
//     none today) fails beside the real ones. While any definition exists, every call resolves through it.
//   - The DEF side's last form counts any `name:` / `name =` key or variable as a definition, so a
//     data key or local of the name (`close:` in a theme table, a local `add = ->`) keeps a call of
//     it resolved after every real method of that name is gone.
//   - Block regexes (`///…///`) are not masked. Measured 2026-07-15: zero call-shaped tokens hide
//     in one, so masking them would add regex-vs-division guesswork for no gain. The one probe
//     artifact of this kind (`.times(` inside `/\.times([^\w\d])/` in LCLCodePreprocessor.coffee)
//     resolves for real — `Number::times` is defined in src/boot/numbertimes.coffee:44 — once the
//     prototype-extension DEF_FORM (lib/name-definitions.js) is harvested.
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
//        --self-test        (in-memory fixtures for the masker + both harvests; needs no repo)

const fs = require('fs');
const path = require('path');
// The DEF side — its comment strip, its DEF_FORMS, the harvest — is the shared
// lib/name-definitions.js, which check-part-edges.js reads too: one implementor harvest, not two.
const defs = require('./lib/name-definitions.js');

const SRC = path.resolve(__dirname, '../src');
const HARNESS = path.resolve(__dirname, '../../Fizzygum-tests/Automator-and-test-harness-src');
const ALLOWLIST = path.resolve(__dirname, 'unresolved-sends-allowlist.txt');

// ─── masking machinery ──────────────────────────────────────────────────────────────────────────

// Pull the CODE out of `#{…}` interpolations in a double-quoted string BODY. Interpolation is a
// double-quote-only feature in CoffeeScript ('…' and '''…''' bodies are literal), and it is real
// code — a method called ONLY as "…#{@foo()}…" is a genuine send. (check-dead-methods makes the
// mirror-image choice for the same reason: interpolation is code, not text.)
function interpolatedCode(body) {
  let out = '';
  for (let i = 0; i < body.length - 1; i++) {
    if (body[i] !== '#' || body[i + 1] !== '{') continue;
    let depth = 1, j = i + 2;
    for (; j < body.length && depth > 0; j++) {
      if (body[j] === '{') depth++;
      else if (body[j] === '}') depth--;
    }
    out += ' ' + body.slice(i + 2, depth > 0 ? body.length : j - 1) + ' ';
    i = j - 1;
  }
  return out;
}

// CALL side: strip `#` comments and string literals, carrying multi-line string state across lines,
// but KEEP interpolated code. Structure copied from check-layering.js's stripLine (kept in sync by
// eye; the interpolation carve-out is this gate's addition). Returns { code, state }.
function stripLine(line, state) {
  if (state) {                                   // currently inside a multi-line string
    const end = line.indexOf(state);
    if (end < 0) return { code: state === '"""' ? interpolatedCode(line) : '', state };
    const body = line.slice(0, end);
    const head = state === '"""' ? interpolatedCode(body) : '';
    line = line.slice(end + state.length);
    state = null;
    const rest = stripLine(line, null);
    return { code: head + rest.code, state: rest.state };
  }
  let out = '';
  let i = 0;
  while (i < line.length) {
    const three = line.substr(i, 3);
    if (three === '"""' || three === "'''") {
      const close = line.indexOf(three, i + 3);
      if (close < 0) {
        if (three === '"""') out += interpolatedCode(line.slice(i + 3));
        return { code: out, state: three };
      }
      if (three === '"""') out += interpolatedCode(line.slice(i + 3, close));
      i = close + 3; continue;
    }
    const c = line[i];
    if (c === '`') {                             // JS passthrough — mask it (fail-open)
      const close = line.indexOf('`', i + 1);
      if (close < 0) return { code: out, state: '`' };
      i = close + 1; continue;
    }
    if (c === '"' || c === "'") {                // single-line quoted string
      let j = i + 1;
      while (j < line.length) {
        if (line[j] === '\\') { j += 2; continue; }
        if (line[j] === c) break;
        j++;
      }
      if (c === '"') out += interpolatedCode(line.slice(i + 1, Math.min(j, line.length)));
      i = j + 1; continue;
    }
    if (c === '#') break;                         // comment to end of line
    out += c; i++;
  }
  return { code: out, state };
}

function walk(dir, ext, acc) {
  if (!fs.existsSync(dir)) return acc;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, ext, acc);
    else if (e.name.endsWith(ext)) acc.push(p);
  }
  return acc;
}

// ─── the implementors ("defs") harvest ──────────────────────────────────────────────────────────
// The forms (and why each is there) live in lib/name-definitions.js's DEF_FORMS; this reads files.
function harvestDefs(files) {
  const defined = new Set();
  for (const p of files) defs.harvestDefs(fs.readFileSync(p, 'utf8').split('\n'), defined);
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

// label a path for the report: src-relative, or harness/<file>
function label(p) {
  return p.startsWith(SRC) ? 'src/' + path.relative(SRC, p)
       : 'harness/' + path.relative(HARNESS, p);
}

function harvestCalls(files) {
  const sites = [];   // { name, at, text }
  for (const p of files) {
    let state = null;
    fs.readFileSync(p, 'utf8').split('\n').forEach((raw, i) => {
      const r = stripLine(raw, state);
      state = r.state;
      let m;
      CALL_RE.lastIndex = 0;
      while ((m = CALL_RE.exec(r.code)) !== null) {
        if (/^[A-Z]/.test(m[2])) continue;   // class-ish reference — the dependency finder's jurisdiction
        const recv = m[1] === '.' ? literalReceiver(r.code, m.index) : undefined;
        sites.push({ name: m[2], sigil: m[1], recv, at: `${label(p)}:${i + 1}`, text: raw.trim().slice(0, 110) });
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
push pop shift slice concat join filter forEach some every indexOf lastIndexOf includes sort reverse fill keys values
charAt charCodeAt fromCharCode toLowerCase toUpperCase trim trimEnd split replace match search padStart repeat substring substr
toString toFixed valueOf hasOwnProperty toJSON
sqrt pow random atan atan2 sin cos asin exp log sign
now parse stringify getOwnPropertyNames
getContext measureText beginPath closePath stroke clip save restore translate scale setTransform drawImage getImageData createPattern
preventDefault appendChild createElement getElementById getElementsByTagName querySelectorAll focus blur click
then resolve all call test exec toDataURL
has get clear
open
isInteger isFinite isView
getTime getHours getMinutes getSeconds getMilliseconds
Math.abs Math.floor Math.ceil Math.round Math.min Math.max Array.isArray Array.from
`.trim().split(/\s+/);
const BUILTINS = new Set(BUILTINS_TABLE.filter((e) => !e.includes('.')));          // bare: any receiver
const BUILTINS_KEYED = new Set(BUILTINS_TABLE.filter((e) => e.includes('.')));    // `Recv.name`: that receiver only
// The platform's own globals, as a call's literal receiver: what a keyed entry may name, and what makes a
// bare shared name "only ever sent to the platform". A fact about the platform; an entry no BUILTINS
// call is sent to fails as stale, and one naming a Fizzygum class fails outright.
const PLATFORM_GLOBALS = new Set(`
Math Object Array ArrayBuffer Number String JSON Date Promise performance console document window
`.trim().split(/\s+/));

// ─── --self-test: prove the pure parts on in-memory fixtures (a lint that can't fail is worthless) ──
if (process.argv.includes('--self-test')) {
  let ok = true;
  const check = (label, got, want) => {
    const pass = JSON.stringify(got) === JSON.stringify(want);
    console[pass ? 'log' : 'error'](`  ${pass ? 'ok  ' : 'FAIL'} ${label} -> ${JSON.stringify(got)}${pass ? '' : ` (expected ${JSON.stringify(want)})`}`);
    if (!pass) ok = false;
  };
  // masker: strings/comments masked, interpolation kept
  const code1 = (l) => stripLine(l, null).code;
  check('call in a comment is masked',        /@foo\(/.test(code1('x = 1 # @foo()')), false);
  check('call in a string is masked',         /@foo\(/.test(code1('x = "@foo()"')), false);
  check("call in a '-string is masked",       /@foo\(/.test(code1("x = '@foo()'")), false);
  check('call in interpolation is KEPT',      /@foo\(/.test(code1('x = "a#{@foo()}b"')), true);
  check('plain call survives',                /@foo\(/.test(code1('@foo()')), true);
  check('heredoc opens multi-line state',     stripLine('x = """', null).state, '"""');
  check('heredoc body masked, interp kept',   stripLine('@a() #{@b()}', '"""').code.includes('@b()'), true);
  check('heredoc body code masked',           stripLine('@a() #{@b()}', '"""').code.includes('@a()'), false);
  // def harvest: every form the probe proved necessary
  const defsOf = (src) => {
    const f = path.join(require('os').tmpdir(), `__ust_${process.pid}.coffee`);
    fs.writeFileSync(f, src); const d = harvestDefs([f]); fs.unlinkSync(f); return [...d].sort();
  };
  check('2-space class method',  defsOf('  myMethod: (a) ->\n').includes('myMethod'), true);
  check('prototype extension',   defsOf('Number::toRadians = ->\n').includes('toRadians'), true);
  check('static fn',             defsOf('Math.getRandomInt = (min, max) ->\n').includes('getRandomInt'), true);
  check('local-proto expando',   defsOf('  swContextProto.useLogicalPixels = ->\n').includes('useLogicalPixels'), true);
  check('bare local fn',         defsOf('helper = ->\n').includes('helper'), true);
  check('plain property key',    defsOf('  bounds: nil\n').includes('bounds'), true);
  check('@-assignment key',      defsOf('    @myField = 3\n').includes('myField'), true);
  // the DEF forms are line-ANCHORED, so a def inside a mid-line string is not harvested…
  check('mid-line string def not harvested',   defsOf('x = "  fake: ->"\n').includes('fake'), false);
  // …but a heredoc BODY line is (the naive strip keeps string content). Over-approximating like this
  // is HARMLESS by construction: an extra implementor can only ever SUPPRESS a flag, never raise one.
  check('heredoc-body def over-approximated', defsOf('code = """\n  fake: ->\n"""\n').includes('fake'), true);
  // call harvest: capitals skipped
  const callsOf = (src) => {
    const f = path.join(require('os').tmpdir(), `__ust_${process.pid}.coffee`);
    fs.writeFileSync(f, src); const c = harvestCalls([f]).map((s) => s.name); fs.unlinkSync(f); return c;
  };
  check('member + self calls harvested', callsOf('@aa()\nx.bb()\n'), ['aa', 'bb']);
  check('Capitalised name skipped',      callsOf('x.Foo()\n'), []);
  // the receiver a keyed BUILTINS entry is matched against: a bare identifier right before the dot only
  const recvsOf = (src) => {
    const f = path.join(require('os').tmpdir(), `__ust_${process.pid}.coffee`);
    fs.writeFileSync(f, src); const c = harvestCalls([f]).map((s) => s.recv || '-'); fs.unlinkSync(f); return c;
  };
  check('literal global receiver read',      recvsOf('x = Math.round(y)\nJSON.parse(s)\nf(Math.max(1, 2))\n'), ['Math', 'JSON', 'Math']);
  check('a spaced dot is no receiver',       recvsOf('y = Math .floor(z)\n'), ['-']);
  check('an interpolation is no receiver',   recvsOf('x = "a#{Math}".round(y)\ny = "#{q} #{document}".createElement(z)\n'), ['-', '-']);
  check('an expression is no receiver',      recvsOf('@bounds.round()\na.Math.round()\n(x).round()\nlist[0].round()\n'), ['-', '-', '-', '-']);
  check('@-self call has no receiver',       recvsOf('@round()\n'), ['-']);
  check('a string is no receiver',           recvsOf('"Math".round()\n'), ['-']);
  console.log(ok ? '[unresolved-sends] self-test PASS' : '[unresolved-sends] self-test FAIL');
  process.exit(ok ? 0 : 1);
}

// ─── run ────────────────────────────────────────────────────────────────────────────────────────
if (!fs.existsSync(SRC)) {
  console.error('[unresolved-sends] ERROR — cannot find src/ — run from the Fizzygum repo root.');
  process.exit(2);
}
if (!fs.existsSync(HARNESS)) {
  console.log('[unresolved-sends] SKIP — sibling Fizzygum-tests not present (its harness is part of the definition universe).');
  process.exit(0);
}

const files = [...walk(SRC, '.coffee', []), ...walk(HARNESS, '.coffee', [])];
const defined = harvestDefs(files);
const sites = harvestCalls(files);

const allow = new Map();   // name -> reason
if (fs.existsSync(ALLOWLIST)) {
  for (const l of fs.readFileSync(ALLOWLIST, 'utf8').split('\n')) {
    const t = l.trim();
    if (!t || t.startsWith('#')) continue;
    const hash = t.indexOf('#');
    allow.set((hash < 0 ? t : t.slice(0, hash)).trim(), hash < 0 ? '' : t.slice(hash + 1).trim());
  }
}

// name -> sites, for every call that resolves to nothing we know about
const unresolved = new Map();
const builtinExcuses = (s) => BUILTINS.has(s.name) || (s.recv !== undefined && BUILTINS_KEYED.has(s.recv + '.' + s.name));
for (const s of sites) {
  if (defined.has(s.name) || builtinExcuses(s)) continue;
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
  .map((n) => `BUILTINS ${n} — no \`[@.]${n}(\` call in src+harness sends it`)
  .concat([...BUILTINS_KEYED].filter((e) => !sentKeyed.has(e))
    .map((e) => `BUILTINS ${e} — no \`${e}(\` call in src+harness sends it`));
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
const formErrors = unkeyed.map((n) => `BUILTINS_NOT_KEYED ${n} — Fizzygum defines ${n}, and every \`.${n}(\` call sends it to a platform global (` +
    [...new Set(sites.filter((s) => s.name === n).map((s) => s.recv))].join(', ') + `): list it keyed, as Recv.${n}, so it excuses only those`)
  .concat(nothingToUnmask.map((e) => `BUILTINS_KEYED_NOTHING_TO_UNMASK ${e} — no definition of ${keyName(e)} is in src+harness: list it bare`))
  .concat([...BUILTINS_KEYED].filter((e) => !PLATFORM_GLOBALS.has(keyReceiver(e)))
    .map((e) => `BUILTINS_KEYED_OFF_PLATFORM ${e} — ${keyReceiver(e)} is not one of PLATFORM_GLOBALS`))
  .concat([...PLATFORM_GLOBALS].filter((g) => classNames.has(g))
    .map((g) => `PLATFORM_GLOBALS_NAMES_FIZZYGUM ${g} — ${g} is a Fizzygum class: its methods are Fizzygum's to define, not the platform's`))
  .concat(staleGlobals.map((g) => `STALE_ALLOWLIST_ENTRY PLATFORM_GLOBALS ${g} — no BUILTINS call in src+harness is sent to ${g}`));
const stale = [...allow.keys()].filter((n) => !unresolved.has(n)).sort().map((n) =>
  `${n} — ${!sent.has(n) ? 'no `[@.]' + n + '(` call is left in src+harness'
    : defined.has(n) ? 'it resolves: a definition of it is in src+harness'
    : 'it is a BUILTINS name'}`);

if (stale.length) {
  console.error(`\n[unresolved-sends] FAIL — ${stale.length} stale entr${stale.length === 1 ? 'y' : 'ies'} in buildSystem/unresolved-sends-allowlist.txt (delete each):`);
  for (const s of stale) console.error(`  STALE_ALLOWLIST_ENTRY ${s}`);
}
if (unsentBuiltins.length) {
  console.error(`\n[unresolved-sends] FAIL — ${unsentBuiltins.length} BUILTINS entr${unsentBuiltins.length === 1 ? 'y' : 'ies'} in check-unresolved-sends.js that no call sends (delete each):`);
  for (const s of unsentBuiltins) console.error(`  STALE_ALLOWLIST_ENTRY ${s}, so it would only excuse the deletion of a future same-named Fizzygum method`);
}
if (formErrors.length) {
  console.error(`\n[unresolved-sends] FAIL — ${formErrors.length} BUILTINS entr${formErrors.length === 1 ? 'y' : 'ies'} in check-unresolved-sends.js in the wrong form:`);
  for (const e of formErrors) console.error(`  ${e}`);
}

if (violations.length) {
  const n = violations.reduce((a, v) => a + unresolved.get(v).length, 0);
  console.error(`\n[unresolved-sends] FAIL — ${n} call site(s) across ${violations.length} name(s) with no definition in src+harness:`);
  for (const name of violations) {
    for (const s of unresolved.get(name)) {
      console.error(`  ${s.at}: ${s.sigil}${name}( — no definition found in src+harness`);
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

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
// (docs/lint-ratchet-static-checks-plan.md): soundness beats reach. That trade is implemented as a
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
//     `@`-self sends are a v2 item (plan §8.7).
//   - Block regexes (`///…///`) are not masked. Measured 2026-07-15: zero call-shaped tokens hide
//     in one, so masking them would add regex-vs-division guesswork for no gain. The one probe
//     artifact of this kind (`.times(` inside `/\.times([^\w\d])/` in LCLCodePreprocessor.coffee)
//     resolves for real — `Number::times` is defined in src/boot/numbertimes.coffee:44 — once the
//     prototype-extension DEF_FORM below is harvested.
//
// EXEMPTIONS — two lists:
//   BUILTINS (in-file, below)              — JS/DOM/canvas platform API. A fact about the platform.
//   unresolved-sends-allowlist.txt (file)  — vendor + genuinely-dynamic names, `name  # reason`.
//                                            A fact about Fizzygum's dependencies.
//
// Exit codes: 0 clean · 1 unresolved send not exempted · 2 operational error.
// Flags: --update-allowlist (re-seed the allowlist with the current unresolved set)
//        --self-test        (in-memory fixtures for the masker + both harvests; needs no repo)

const fs = require('fs');
const path = require('path');

const SRC = path.resolve(__dirname, '../src');
const HARNESS = path.resolve(__dirname, '../../Fizzygum-tests/Automator-and-test-harness-src');
const ALLOWLIST = path.resolve(__dirname, 'unresolved-sends-allowlist.txt');

// ─── masking machinery ──────────────────────────────────────────────────────────────────────────

// DEF side: cut at the first '#' that does NOT open a `#{…}` interpolation (verbatim from
// check-dead-methods.js — strings are deliberately KEPT, see the soundness trade above).
function stripComment(line) {
  for (let k = line.indexOf('#'); k >= 0; k = line.indexOf('#', k + 1)) {
    if (line[k + 1] !== '{') return line.slice(0, k);
  }
  return line;
}

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
// Every shape that can put a callable name into the world. The 2-space class-body form is the
// canonical HEADER every other gate keys off; the rest are the forms the 2026-07-15 probe proved it
// needs (each false positive it reported was one of these, not a real bug).
const DEF_FORMS = [
  /^  ([A-Za-z_$][\w$]*)\s*:\s*(\([^)]*\)\s*)?[-=]>/,                          // 2-space class-body method  (the canonical HEADER)
  /^\s*([A-Za-z_$][\w$]*)\s*:\s*(\([^)]*\)\s*)?[-=]>/,                         // any-indent object-literal / mixin-DSL member fn
  /^\s*[A-Za-z_$][\w$]*::([A-Za-z_$][\w$]*)\s*=/,                              // prototype extension        (Number::toRadians = ->)
  /^\s*[A-Za-z_$][\w$.]*\.([A-Za-z_$][\w$]*)\s*=\s*(\([^)]*\)\s*)?[-=]>/,      // static / expando fn        (Math.getRandomInt = …, swContextProto.foo = …)
  /^\s*([A-Za-z_$][\w$]*)\s*=\s*(\([^)]*\)\s*)?[-=]>/,                         // bare local fn              (helper = ->)
  /^\s*@?([A-Za-z_$][\w$]*)\s*[:=]/,                                           // ANY other property key — over-approximate ON PURPOSE (a property may hold a closure)
];

function harvestDefs(files) {
  const defined = new Set();
  for (const p of files) {
    for (const raw of fs.readFileSync(p, 'utf8').split('\n')) {
      const line = stripComment(raw);
      for (const re of DEF_FORMS) {
        const m = re.exec(line);
        if (m) defined.add(m[1]);
      }
    }
  }
  return defined;
}

// ─── the senders ("calls") harvest ──────────────────────────────────────────────────────────────
const CALL_RE = /([@.])([A-Za-z_$][\w$]*)\(/g;   // group 1 = the receiver sigil, kept so the report can echo the real call shape

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
        sites.push({ name: m[2], sigil: m[1], at: `${label(p)}:${i + 1}`, text: raw.trim().slice(0, 110) });
      }
    });
  }
  return sites;
}

// ─── the platform (JS / DOM / canvas builtins) ──────────────────────────────────────────────────
// A fact about the PLATFORM, not about Fizzygum — hence in-file, not in the allowlist. Seeded from
// the 2026-07-15 probe; extend when a genuinely-standard API surfaces.
const BUILTINS = new Set(`
push pop shift unshift slice splice concat join map filter forEach reduce reduceRight some every find findIndex indexOf lastIndexOf includes sort reverse flat flatMap fill keys values entries
charAt charCodeAt codePointAt fromCharCode toLowerCase toUpperCase trim trimStart trimEnd split replace replaceAll match matchAll search startsWith endsWith padStart padEnd repeat substring substr localeCompare normalize
toString toFixed toPrecision valueOf hasOwnProperty isPrototypeOf propertyIsEnumerable toLocaleString toJSON
abs floor ceil round sqrt pow min max random atan atan2 sin cos tan asin acos exp log log2 sign hypot trunc cbrt
now parse stringify freeze assign create defineProperty getOwnPropertyNames getPrototypeOf setPrototypeOf isArray from of
getContext fillRect strokeRect clearRect fillText strokeText measureText beginPath closePath moveTo lineTo bezierCurveTo quadraticCurveTo arc arcTo ellipse rect fill stroke clip save restore translate rotate scale transform setTransform resetTransform drawImage createImageData getImageData putImageData createLinearGradient createRadialGradient createPattern addColorStop setLineDash getLineDash isPointInPath isPointInStroke
addEventListener removeEventListener dispatchEvent preventDefault stopPropagation stopImmediatePropagation getBoundingClientRect appendChild removeChild insertBefore setAttribute getAttribute removeAttribute createElement createTextNode getElementById getElementsByTagName querySelector querySelectorAll focus blur click
setTimeout clearTimeout setInterval clearInterval requestAnimationFrame cancelAnimationFrame
then catch finally resolve reject all race apply call bind test exec toDataURL toBlob
add delete has get set clear next done readAsDataURL readAsText readAsArrayBuffer
log warn error info debug trace group groupEnd table time timeEnd assert dir count
open close write send setRequestHeader overrideMimeType getResponseHeader abort
postMessage item namedItem contains matches closest remove append prepend before after
isInteger isFinite isNaN parseFloat parseInt charCode keyCode preventExtensions
stopImmediate propagation getTime getFullYear getMonth getDate getHours getMinutes getSeconds getMilliseconds getDay toISOString toUTCString getTimezoneOffset
requestFullscreen exitFullscreen webkitRequestFullscreen mozRequestFullScreen msRequestFullscreen
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
for (const s of sites) {
  if (defined.has(s.name) || BUILTINS.has(s.name)) continue;
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
    '# The gate FAILS on any unresolved send not listed here.\n\n';
  fs.writeFileSync(ALLOWLIST, header + names.map((n) => `${n}  # TODO: reason`).join('\n') + '\n');
  console.log(`[unresolved-sends] wrote ${names.length} name(s) to ${path.relative(process.cwd(), ALLOWLIST)}`);
  process.exit(0);
}

const violations = [...unresolved.keys()].filter((n) => !allow.has(n)).sort();
const stale = [...allow.keys()].filter((n) => !unresolved.has(n)).sort();

if (stale.length) {
  console.log(`[unresolved-sends] NOTE — ${stale.length} allowlist entr${stale.length === 1 ? 'y' : 'ies'} now resolve(s) (delete from buildSystem/unresolved-sends-allowlist.txt): ${stale.join(', ')}`);
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

console.log(`[unresolved-sends] OK — ${sites.length} calls checked, 0 unresolved (${defined.size} names implemented, ${allow.size} allowlisted).`);
process.exit(0);

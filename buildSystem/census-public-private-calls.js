#!/usr/bin/env node
'use strict';
/*
 * census-public-private-calls.js — the public/private SELF-call census: an ANALYSIS CLI *and* the
 * measurement ENGINE behind the check-call-separation.js gate (rules [S]/[U] — see
 * docs/public-private-call-separation-plan.md; gate reference: docs/lint-and-static-checks.md).
 *
 * Two entry points, one engine:
 *   - CLI (this file run directly): human-readable report of the four censuses below.
 *   - module (require(...).runCensus()): the same data, machine-shaped, for the gate.
 *
 * WHAT IT MEASURES (four censuses; "self-call" = `@name …` where `name` is a method somewhere in
 * the calling class's inheritance chain — own defs, `@augmentWith` mixins, `extends` ancestors):
 *
 *   R1  private → public self-call. Every CALL from a low-level method (leading `_`/`__`, or
 *       `*NoSettle` — same tiering as check-layering.js isLowLevel) to a public (no-underscore)
 *       method of the same object. Each callee is classified:
 *         SETTLING    — transitively reaches a settle (@_settleLayoutsAfter* or recalculateLayouts)
 *                       through @-self calls, or member-calls a known settling setter
 *                       (setExtent/moveTo/setBounds/setWidth/setHeight + the 7 text setters).
 *         EFFECTFUL   — transitively mutates state (own-field assignment [cache/memo/counter/hash
 *                       fields carved out — memoizing getters are morally queries], collection
 *                       mutation on an own field, changed/fullChanged, _invalidateLayout) but
 *                       never settles.
 *         REACT-VERB  — the callee is changed/fullChanged: the DESIGNED react step, legitimate
 *                       from `_` tier (rule [I] bans it only in `__` leaves). Never a violation.
 *         QUERY       — none of the above (pure by this analysis). Legitimate from private code.
 *       Rule [S]'s subject is SETTLING + EFFECTFUL ("hard sites"); a site whose CALLER method
 *       carries a `# public-call-sanctioned: <why>` marker is reported but not counted.
 *
 *   R2  public → public SETTLING self-call. Most hits are the DESIGNED dispatcher pattern (a
 *       public event entry delegating to one settling command per event — processKeyDown→goLeft,
 *       closeButtonInBarPressed→close) and are NOT violations. The NARROWED subset — the caller's
 *       OWN body settles directly AND it calls another settling public method — is the true
 *       double-flush shape; the static twin is check-layering.js rule [T] (which keys off the
 *       textual `_settleLayoutsAfter` callers; this census's narrowed set is the transitive
 *       superset, reported for review).
 *
 *   R3  literal "mixed use" — methods whose body self-calls BOTH a public and a private method.
 *       Informational only; measured 2026-07-12 to be dominated by benign query mixing, hence
 *       REJECTED as a rule (plan §8).
 *
 *   R4  privatization candidates — public methods whose EVERY reference across src + the sibling
 *       test harness + the macro tests is a `@`-self call: never a `.member` call, never inside a
 *       string (menu/connection dispatch is name-string-driven, so strings count), never a bare
 *       identifier, never referenced in Fizzygum-tests. Provably not external API → candidates for
 *       a `_` rename (rule [U]; deliberate end-user API goes in buildSystem/public-api-allowlist.txt).
 *       NEEDS the sibling Fizzygum-tests repo; R4 is null (and rule [U] SKIPS) when it is absent.
 *
 * HOW (same philosophy as the check-*.js gates — a heuristic line scanner, no type inference):
 *   - Parsing machinery is copied from check-layering.js: stripLine (strips # comments + string
 *     literals with multi-line state) and the 2-space METHOD_HEADER grouping, mixin-DSL aware.
 *   - Class = file basename (one-class-per-file); `extends` / `@augmentWith` edges regex-scanned
 *     exactly like src/boot/dependencies-finding.coffee does.
 *   - A `@name` occurrence counts as a CALL when followed by `(`, or by whitespace + a value token
 *     that is not an operator/keyword (`@foo bar` calls; `@foo if x`, bare `@foo`, `@foo = …`,
 *     `@foo.bar` do not). Markers are read from the RAW line (they live in comments).
 *   - Effect/settle classification is a fixpoint over the @-SELF call graph only. NB this is NOT
 *     the rejected [G] transitive closure (that was BACKWARD reachability including `.`-member
 *     calls and `new` constructor hubs — ~500-710 false hits, docs/lint-and-static-checks.md §7);
 *     forward closure restricted to @-self calls converges cleanly (2 SETTLING hits at baseline).
 *
 * KNOWN BLIND SPOTS (accepted; the census sizes and triages, the runtime throws stay the backstop):
 *   - dynamic dispatch (`@[name]()`, string-dispatched menu/connection actions) is invisible to
 *     call extraction (R4 DOES see the strings, so string-dispatched names are never candidates);
 *   - CoffeeScript soak calls `@foo?()` count as references, not calls (10 sites tree-wide,
 *     measured 2026-07-12 — negligible);
 *   - a field named identically to a chain method can inflate REFERENCE counts (calls need a
 *     call-shaped tail, so call counts are safe);
 *   - `.moveTo` on a canvas context is excluded from the settling-member heuristic (the same
 *     Point/canvas collision check-layering.js rule [A] carves out).
 *
 * USAGE (run from the Fizzygum/ repo root, like the gates):
 *   node ./buildSystem/census-public-private-calls.js            # summary + truncated lists
 *   node ./buildSystem/census-public-private-calls.js --full     # untruncated site/name lists
 *   node ./buildSystem/census-public-private-calls.js --json o.json   # machine-readable dump
 *   node ./buildSystem/census-public-private-calls.js --self-test     # call-extractor fixtures
 *
 * CLI exit codes: 0 = ran (the CLI never "fails" on findings — enforcement is
 * check-call-separation.js's job), 2 = operational error.
 */

const fs = require('fs');
const path = require('path');

const SRC = path.resolve(__dirname, '../src');
const TESTS = path.resolve(__dirname, '../../Fizzygum-tests/tests');
const HARNESS = path.resolve(__dirname, '../../Fizzygum-tests/Automator-and-test-harness-src');

// the [S] per-method conscious sign-off: a hard R1 site whose CALLER carries this marker is
// reported but NOT counted by the gate (mirror of check-layering's nosettle-sanctioned mechanics)
const PUBLIC_CALL_MARKER = 'public-call-sanctioned';
// rule [T]'s marker (owned by check-layering.js) — the census reads it too so its narrowed-R2
// report shows which double-settle shapes are consciously signed off
const DOUBLE_SETTLE_MARKER = 'double-settle-sanctioned';

// ---------- scanner machinery (copied from check-layering.js — keep in sync) ----------
function stripLine(line, state) {
  if (state) {
    const end = line.indexOf(state);
    if (end < 0) return { code: '', state };
    line = line.slice(end + state.length);
    state = null;
  }
  let out = '';
  let i = 0;
  while (i < line.length) {
    const three = line.substr(i, 3);
    if (three === '"""' || three === "'''") {
      const close = line.indexOf(three, i + 3);
      if (close < 0) { state = three; break; }
      i = close + 3; continue;
    }
    const c = line[i];
    if (c === '`') {
      const close = line.indexOf('`', i + 1);
      if (close < 0) { state = '`'; break; }
      i = close + 1; continue;
    }
    if (c === '"' || c === "'") {
      let j = i + 1;
      while (j < line.length) {
        if (line[j] === '\\') { j += 2; continue; }
        if (line[j] === c) break;
        j++;
      }
      i = j + 1; continue;
    }
    if (c === '#') break;
    out += c; i++;
  }
  return { code: out, state };
}

// Per-char mask for one raw line: 'code' | 'str' | 'cut' (comment), carrying the same multi-line
// string state stripLine tracks (""" ''' `), so heredoc bodies mask as 'str'. Where stripLine
// DELETES strings, this only LABELS them — so a caller can keep string CONTENT while still cutting
// comments, and can tell "inside a string" from "code". R4's occurrence harvest needs that (strings
// are dynamic-dispatch surface and must DISQUALIFY a privatization candidate); so does
// census-hierarchy-duplication.js, which must compare method bodies with their string literals
// INTACT (two bodies differing only in a string literal are NOT duplicates). Exported for that
// reason — module-scope, and it captures nothing.
function maskLine(line, state) {
  const mask = new Array(line.length).fill('code');
  let i = 0;
  if (state) {
    const end = line.indexOf(state);
    if (end < 0) { mask.fill('str'); return { mask, state }; }
    for (let j = 0; j < end + state.length; j++) mask[j] = 'str';
    i = end + state.length;
    state = null;
  }
  while (i < line.length) {
    const three = line.substr(i, 3);
    if (three === '"""' || three === "'''") {
      const close = line.indexOf(three, i + 3);
      const stop = close < 0 ? line.length : close + 3;
      for (let j = i; j < stop; j++) mask[j] = 'str';
      if (close < 0) return { mask, state: three };
      i = stop; continue;
    }
    const c = line[i];
    if (c === '`' || c === '"' || c === "'") {
      let j = i + 1;
      while (j < line.length) {
        if (line[j] === '\\') { j += 2; continue; }
        if (line[j] === c) break;
        j++;
      }
      const stop = j >= line.length ? line.length : j + 1;
      for (let k = i; k < stop; k++) mask[k] = 'str';
      if (j >= line.length) return { mask, state: c === '`' ? '`' : null };  // unterminated: only ` spans lines
      i = stop; continue;
    }
    if (c === '#') { for (let j = i; j < line.length; j++) mask[j] = 'cut'; break; }
    i++;
  }
  return { mask, state };
}

const METHOD_HEADER = /^  ([A-Za-z_]\w*): (\(.*?\) )?[-=]>/;
const MIXIN_CONTAINER = 'onceAddedClassProperties';
const MIXIN_METHOD_HEADER = /^( {4,})([A-Za-z_]\w*): (\(.*?\) )?[-=]>/;

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

function collectFiles(dir, ext, out) {
  if (!fs.existsSync(dir)) return out;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) collectFiles(p, ext, out);
    else if (e.name.endsWith(ext)) out.push(p);
  }
  return out;
}

// ---------- tiering (same name-keyed tiers as check-layering.js isLowLevel) ----------
const tierOf = (name) =>
  /^__/.test(name) ? 'leaf' :
  /^_/.test(name) ? 'private' :
  /NoSettle$/.test(name) ? 'private' :
  'public';

// ---------- self-call shape ----------
// keywords that, appearing as the token after `@name `, mean "not an argument" (postfix
// conditional / operator), so the occurrence is a property READ, not a call.
const KEYWORD_NONARG = new Set(['if', 'unless', 'then', 'else', 'and', 'or', 'is', 'isnt',
  'in', 'of', 'not', 'when', 'for', 'while', 'until', 'instanceof']);

// classify the text FOLLOWING a matched `@name` (endIdx = end of the name): call / ref / skip
// (skip = assignment target or receiver-of-member — not a use of the METHOD at all).
function classifyOccurrence(code, endIdx) {
  const after = code.slice(endIdx);
  if (/^\(/.test(after)) return 'call';
  if (/^\s*(\?|\|\||\bor\b|\band\b)?=[^=]/.test(after)) return 'skip';   // @foo = / ?= / or= …
  if (/^\s*\./.test(after)) return 'skip';                               // @foo.bar — receiver
  const tokM = after.match(/^[ \t]+([A-Za-z_]\w*|@|'|"|\[|\{|\(|\d|-\d|=>|->)/);
  if (tokM && !KEYWORD_NONARG.has(tokM[1])) return 'call';               // paren-less args
  return 'ref';
}

// ---------- effect-classification constants ----------
const SETTLE_DIRECT = /[@.]\s*(_settleLayoutsAfter(OrJoinEnclosingPass)?|recalculateLayouts)\b/;
const PUBLIC_SETTERS = ['setExtent', 'moveTo', 'setBounds', 'setWidth', 'setHeight'];
const TEXT_SETTERS = ['setText', 'setFontSize', 'setFontName', 'toggleShowBlanks', 'toggleWeight', 'toggleItalic', 'toggleIsPassword'];
const memberSettleRe = new RegExp('\\.\\s*(' + [...PUBLIC_SETTERS, ...TEXT_SETTERS].join('|') + ')\\b');
// the canvas-context moveTo carve-out (same as check-layering rule [A]'s CANVAS_MOVETO)
const CANVAS_MOVETO = /\b(context|pctx|backBufferContext|aContext|ctx|cacheCtx|targetContext)\s*\.\s*moveTo\b/;
const FIELD_ASSIGN = /@([A-Za-z_]\w*)(\.[A-Za-z_]\w*)*\s*(\?=|\|\|=|\+=|-=|\*=|\/=|=(?![=>]))/;
// memoizing getters / cache hygiene / counters are morally queries — carve their writes out
const CACHEY = /cache|Cache|memo|Memo|_last|Counter|counter|hash|Hash/;
const COLLECTION_MUT = /@[A-Za-z_]\w*\.(push|splice|pop|shift|unshift|sort|reverse|set|delete|clear|add)\b/;
const REPAINT_CALL = /[@.]\s*(changed|fullChanged)\b/;
const SCHEDULE_CALL = /[@.]\s*_invalidateLayout\b/;
// changed/fullChanged are the DESIGNED react steps (naming convention §2 — banned only in __ leaves
// by rule [I]); fullChangedIncludingShadowOwner is the same verb's shadow-aware variant (T3, 2026-07-12).
const REACT_VERBS = new Set(['changed', 'fullChanged', 'fullChangedIncludingShadowOwner']);

// ============================== THE ENGINE ==============================
// Returns { stats, R1, R2, R2narrowed, R3, R4, haveTestsRepo }.
//   R1 row:  { cls, caller, callee, calleeClass, sanctioned, at }
//   R2 row:  { cls, caller, ctor, callerDirectlySettles, sanctioned, callee, at }
//   R4 row:  { name, selfCalls, effectful, defs }   (R4 = null when the tests repo is absent)
function runCensus() {
  if (!fs.existsSync(SRC)) throw new Error('cannot find src/ — run from the Fizzygum repo root');

  // ---- phase 1: parse every src class ----
  const classInfo = new Map();   // name -> { name, parent, mixins[], methods: Map(name->rec), file }
  const allMethods = [];         // rec: { name, cls, file, line, bodyLines: [{n, code}], markers:Set }
  const srcFiles = collectFiles(SRC, '.coffee', []).sort();
  for (const file of srcFiles) {
    const rel = path.relative(SRC, file);
    const clsName = path.basename(file, '.coffee');
    const lines = fs.readFileSync(file, 'utf8').split('\n');
    let info = classInfo.get(clsName);
    if (!info) { info = { name: clsName, parent: null, mixins: [], methods: new Map(), file: rel }; classInfo.set(clsName, info); }
    let mixinHashIndent = null, strState = null, cur = null;
    for (let n = 0; n < lines.length; n++) {
      const raw = lines[n];
      const { code, state } = stripLine(raw, strState);
      strState = state;
      const clsM = raw.match(/^class ([A-Za-z_]\w*)( extends ([A-Za-z_]\w*))?/);
      if (clsM && clsM[1] === clsName) info.parent = clsM[3] || null;
      const augM = code.match(/@augmentWith\s+([A-Za-z_]\w*)/);
      if (augM) info.mixins.push(augM[1]);
      if (strState === null) {
        const b = methodBoundary(raw, mixinHashIndent);
        if (b) {
          mixinHashIndent = b.mixinHashIndent;
          if (b.kind === 'header' && b.method) {
            cur = { name: b.method, cls: clsName, file: rel, line: n + 1, bodyLines: [], markers: new Set() };
            const gt = code.indexOf('>');
            if (gt >= 0 && code.slice(gt + 1).trim()) cur.bodyLines.push({ n: n + 1, code: code.slice(gt + 1) });
            info.methods.set(b.method, cur);
            allMethods.push(cur);
            continue;
          }
          if (b.kind === 'end') { cur = null; continue; }
        }
      }
      if (cur) {
        cur.bodyLines.push({ n: n + 1, code });
        // markers live in comments -> read the RAW line (stripLine would eat them)
        if (raw.includes(PUBLIC_CALL_MARKER)) cur.markers.add(PUBLIC_CALL_MARKER);
        if (raw.includes(DOUBLE_SETTLE_MARKER)) cur.markers.add(DOUBLE_SETTLE_MARKER);
      }
    }
  }

  // ---- phase 2: inheritance-chain resolution (own -> mixins -> parent chain) ----
  const chainCache = new Map();
  function chainOf(cls) {
    if (chainCache.has(cls)) return chainCache.get(cls);
    const seen = new Set(); const order = [];
    const visit = (name) => {
      if (seen.has(name)) return;
      seen.add(name);
      const info = classInfo.get(name);
      if (!info) return;
      order.push(info);
      for (const mx of info.mixins) visit(mx);
      if (info.parent) visit(info.parent);
    };
    visit(cls);
    chainCache.set(cls, order);
    return order;
  }
  function resolve(cls, name) {
    for (const info of chainOf(cls)) { const r = info.methods.get(name); if (r) return r; }
    return null;
  }
  const chainNamesCache = new Map();
  function chainNames(cls) {
    let s = chainNamesCache.get(cls);
    if (!s) {
      s = new Set();
      for (const info of chainOf(cls)) for (const k of info.methods.keys()) s.add(k);
      chainNamesCache.set(cls, s);
    }
    return s;
  }

  // ---- phase 3: extract self-calls per method ----
  for (const rec of allMethods) {
    rec.selfCalls = [];
    for (const { n, code } of rec.bodyLines) {
      const re = /@([A-Za-z_]\w*)/g;
      let m;
      while ((m = re.exec(code)) !== null) {
        const name = m[1];
        if (name === 'constructor' || name === 'augmentWith') continue;
        if (!chainNames(rec.cls).has(name)) continue;   // a field / unknown — not a chain method
        const kind = classifyOccurrence(code, m.index + m[0].length);
        if (kind === 'skip') continue;
        rec.selfCalls.push({ callee: name, n, kind });
      }
    }
  }

  // ---- phase 4: effect/settle classification ----
  for (const rec of allMethods) {
    let settles = false, mutatesNonCache = false, repaints = false, schedules = false, memberSettle = false;
    for (const { code } of rec.bodyLines) {
      if (SETTLE_DIRECT.test(code)) settles = true;
      const fa = code.match(FIELD_ASSIGN);
      if (fa && !CACHEY.test(fa[1])) mutatesNonCache = true;
      if (COLLECTION_MUT.test(code)) mutatesNonCache = true;
      if (REPAINT_CALL.test(code)) repaints = true;
      if (SCHEDULE_CALL.test(code)) schedules = true;
      const mm = code.match(memberSettleRe);
      if (mm && !(mm[1] === 'moveTo' && (CANVAS_MOVETO.test(code) || /boot\/extensions/.test(rec.file)))) memberSettle = true;
    }
    rec.sig = { settles, mutatesNonCache, repaints, schedules, memberSettle };
  }
  // fixpoint over @-self calls only (see the header note on why this is NOT the rejected closure)
  const key = (rec) => rec.cls + '#' + rec.name;
  const settlesT = new Map(), effectT = new Map();
  for (const rec of allMethods) {
    settlesT.set(key(rec), rec.sig.settles || rec.sig.memberSettle);
    effectT.set(key(rec), rec.sig.mutatesNonCache || rec.sig.repaints || rec.sig.schedules || rec.sig.settles || rec.sig.memberSettle);
  }
  let dirty = true, iter = 0;
  while (dirty && iter < 50) {
    dirty = false; iter++;
    for (const rec of allMethods) {
      const k = key(rec);
      let s = settlesT.get(k), e = effectT.get(k);
      if (s && e) continue;
      for (const c of rec.selfCalls) {
        if (c.kind !== 'call') continue;
        const target = resolve(rec.cls, c.callee);
        if (!target) continue;
        const tk = key(target);
        if (!s && settlesT.get(tk)) s = true;
        if (!e && effectT.get(tk)) e = true;
        if (s && e) break;
      }
      if (s && !settlesT.get(k)) { settlesT.set(k, true); dirty = true; }
      if (e && !effectT.get(k)) { effectT.set(k, true); dirty = true; }
    }
  }
  // name-level fallback for callees unresolved in-chain (defensive; chain resolution is primary)
  const nameSettles = new Set(), nameEffect = new Set();
  for (const rec of allMethods) {
    if (settlesT.get(key(rec))) nameSettles.add(rec.name);
    if (effectT.get(key(rec))) nameEffect.add(rec.name);
  }
  function classifyCallee(callerCls, calleeName) {
    const target = resolve(callerCls, calleeName);
    const k = target ? key(target) : null;
    const settles = k ? settlesT.get(k) : nameSettles.has(calleeName);
    const effect = k ? effectT.get(k) : nameEffect.has(calleeName);
    if (settles) return 'SETTLING';
    if (effect) return 'EFFECTFUL';
    return 'QUERY';
  }

  // ---- censuses R1/R2/R3 ----
  const out = { stats: {}, R1: [], R2: [], R2narrowed: [], R3: { public: [], private: [] }, R4: null, haveTestsRepo: false };
  let nPub = 0, nPriv = 0, nLeaf = 0;
  for (const rec of allMethods) {
    const t = tierOf(rec.name);
    if (t === 'public') nPub++; else if (t === 'leaf') nLeaf++; else nPriv++;
  }
  out.stats = { files: srcFiles.length, classes: classInfo.size, methods: allMethods.length, public: nPub, private: nPriv, leaf: nLeaf };

  for (const rec of allMethods) {
    const callerTier = tierOf(rec.name);
    const pubCalls = [], privCalls = [];
    for (const c of rec.selfCalls) {
      if (c.kind !== 'call') continue;
      (tierOf(c.callee) === 'public' ? pubCalls : privCalls).push(c);
    }
    if (callerTier !== 'public') {
      for (const c of pubCalls) {
        const cc = REACT_VERBS.has(c.callee) ? 'REACT-VERB' : classifyCallee(rec.cls, c.callee);
        out.R1.push({ cls: rec.cls, caller: rec.name, callee: c.callee, calleeClass: cc,
          sanctioned: rec.markers.has(PUBLIC_CALL_MARKER), at: rec.file + ':' + c.n });
      }
    }
    if (callerTier === 'public') {
      for (const c of pubCalls) {
        if (classifyCallee(rec.cls, c.callee) !== 'SETTLING') continue;
        const row = { cls: rec.cls, caller: rec.name, ctor: rec.name === 'constructor',
          callerDirectlySettles: rec.sig.settles, sanctioned: rec.markers.has(DOUBLE_SETTLE_MARKER),
          callee: c.callee, at: rec.file + ':' + c.n };
        out.R2.push(row);
        if (rec.sig.settles) out.R2narrowed.push(row);
      }
    }
    if (pubCalls.length > 0 && privCalls.length > 0) {
      out.R3[callerTier === 'public' ? 'public' : 'private'].push({
        cls: rec.cls, caller: rec.name,
        pub: [...new Set(pubCalls.map(c => c.callee))], priv: [...new Set(privCalls.map(c => c.callee))],
        at: rec.file + ':' + rec.line
      });
    }
  }

  // ---- R4: privatization candidates (needs the sibling tests repo) ----
  // Occurrence harvest KEEPS string literals and classifies each occurrence of a public method
  // name. An occurrence INSIDE a string literal bumps 'other' REGARDLESS of its preceding char —
  // strings are dynamic-dispatch / macro-heredoc surface, so they must DISQUALIFY a candidate
  // (the 2026-07-12 T5 lesson: a `Macro.fromString """…"""` heredoc calling `@someToolkitVerb`
  // was classified 'self' by the preceding-char rule, letting a de-facto macro-surface verb into
  // the rename list — the rename then tripped rule [D]). Outside strings: `@` self / `.` member /
  // bare "other". Comments are not counted; own def headers are excluded.
  const publicNames = new Set();
  for (const rec of allMethods) if (tierOf(rec.name) === 'public') publicNames.add(rec.name);
  const nameOcc = new Map();   // name -> {self, member, other, external, defs}
  const bump = (name, kind) => {
    let o = nameOcc.get(name);
    if (!o) nameOcc.set(name, (o = { self: 0, member: 0, other: 0, external: 0, defs: 0 }));
    o[kind]++;
  };
  const WORD = /[A-Za-z_]\w*/g;
  for (const file of srcFiles) {
    let mState = null;
    for (const raw of fs.readFileSync(file, 'utf8').split('\n')) {
      const { mask, state } = maskLine(raw, mState);
      mState = state;
      let m;
      WORD.lastIndex = 0;
      while ((m = WORD.exec(raw)) !== null) {
        const name = m[0];
        if (!publicNames.has(name)) continue;
        const where = mask[m.index] || 'code';
        if (where === 'cut') continue;                           // comment — not counted
        if (where === 'str') { bump(name, 'other'); continue; }  // in-string — disqualifies
        const isDef = (METHOD_HEADER.test(raw) && raw.trimStart().startsWith(name + ':')) ||
                      (MIXIN_METHOD_HEADER.test(raw) && new RegExp('^\\s+' + name + ':').test(raw));
        if (isDef) { bump(name, 'defs'); continue; }
        const before = m.index > 0 ? raw[m.index - 1] : '';
        bump(name, before === '@' ? 'self' : before === '.' ? 'member' : 'other');
      }
    }
  }
  out.nameOcc = nameOcc;
  out.haveTestsRepo = fs.existsSync(TESTS) && fs.existsSync(HARNESS);
  if (out.haveTestsRepo) {
    const harvestExternal = (files, isCoffee) => {
      for (const p of files) {
        for (const raw of fs.readFileSync(p, 'utf8').split('\n')) {
          const hashIdx = isCoffee ? raw.indexOf('#') : -1;
          const line = hashIdx >= 0 ? raw.slice(0, hashIdx) : raw;
          let m;
          WORD.lastIndex = 0;
          while ((m = WORD.exec(line)) !== null) if (publicNames.has(m[0])) bump(m[0], 'external');
        }
      }
    };
    harvestExternal(collectFiles(HARNESS, '.coffee', []), true);
    harvestExternal(collectFiles(TESTS, '.js', []), false);
    const R4 = [];
    for (const name of publicNames) {
      const o = nameOcc.get(name) || { self: 0, member: 0, other: 0, external: 0 };
      if (o.self > 0 && o.member === 0 && o.other === 0 && o.external === 0) {
        const defRecs = allMethods.filter(r => r.name === name);
        const anyEffectful = defRecs.some(r => effectT.get(key(r)));
        R4.push({ name, selfCalls: o.self, effectful: anyEffectful, defs: defRecs.map(r => r.cls) });
      }
    }
    out.R4 = R4.sort((a, b) => b.selfCalls - a.selfCalls || (a.name < b.name ? -1 : 1));
  }
  out.allMethodNames = new Set(allMethods.map(r => r.name));
  out.allMethods = allMethods;
  // The whole-system CLASS MODEL, exposed so sibling censuses don't re-implement it. Fizzygum is
  // image-like (no module system, one class per file, every class a global), so this model — every
  // class's parent, @augmentWith mixins, methods, and the resolution order over them — is the
  // expensive, subtle part that any hierarchy-aware analysis needs. Consumers:
  // census-hierarchy-duplication.js and census-property-placement.js (2026-07-15). Purely
  // additive: nothing here changes the four censuses or the [S]/[U] gate numbers.
  //   classInfo : Map(className -> { name, parent, mixins[], methods: Map(name -> rec), file })
  //   chainOf   : (cls) -> [classInfo…] in RESOLUTION order (own, then mixins, then parent chain)
  //   resolve   : (cls, methodName) -> the winning method rec, or null
  out.classInfo = classInfo;
  out.chainOf = chainOf;
  out.resolve = resolve;
  return out;
}

module.exports = { runCensus, PUBLIC_CALL_MARKER, DOUBLE_SETTLE_MARKER, tierOf, classifyOccurrence, maskLine, METHOD_HEADER };

// ============================== THE CLI ==============================
if (require.main === module) {
  // --self-test: prove the call-shape decisions on fixtures (no repo needed).
  if (process.argv.includes('--self-test')) {
    const CASES = [
      ['@foo()', 'foo', 'call'], ['@foo(a, b)', 'foo', 'call'],
      ['@foo a', 'foo', 'call'], ['@foo @bar', 'foo', 'call'], ["@foo 'x'", 'foo', 'call'],
      ['@foo if x', 'foo', 'ref'], ['@foo and @bar', 'foo', 'ref'], ['x = @foo', 'foo', 'ref'],
      ['@foo = 3', 'foo', 'skip'], ['@foo ?= 3', 'foo', 'skip'], ['@foo.bar()', 'foo', 'skip'],
      ['return unless @foo', 'foo', 'ref'],
    ];
    let ok = true;
    for (const [line, name, expect] of CASES) {
      const got = classifyOccurrence(line, line.indexOf('@' + name) + 1 + name.length);
      if (got !== expect) ok = false;
      console.log(`  ${got === expect ? 'ok  ' : 'FAIL'} ${JSON.stringify(line)} -> ${got} (expected ${expect})`);
    }
    console.log(ok ? '[census] self-test PASS' : '[census] self-test FAIL');
    process.exit(ok ? 0 : 1);
  }

  const FULL = process.argv.includes('--full');
  const jsonIdx = process.argv.indexOf('--json');
  const JSON_OUT = jsonIdx >= 0 ? process.argv[jsonIdx + 1] : null;

  let out;
  try { out = runCensus(); }
  catch (e) { console.error('[census] ' + e.message); process.exit(2); }

  const trunc = (arr, n) => (FULL ? arr : arr.slice(0, n));
  console.log('=== census-public-private-calls ===');
  console.log('stats: ' + JSON.stringify(out.stats));

  console.log('\n=== R1: private -> public self-call ===');
  const r1by = {};
  for (const r of out.R1) r1by[r.calleeClass] = (r1by[r.calleeClass] || 0) + 1;
  console.log('by callee class: ' + JSON.stringify(r1by) + `  (total ${out.R1.length} sites, ${new Set(out.R1.map(r => r.cls + '#' + r.caller)).size} callers)`);
  const r1hard = out.R1.filter(r => r.calleeClass === 'SETTLING' || r.calleeClass === 'EFFECTFUL');
  const r1sanctioned = r1hard.filter(r => r.sanctioned);
  console.log(`hard sites (SETTLING+EFFECTFUL): ${r1hard.length} across ${new Set(r1hard.map(r => r.cls)).size} classes (${r1sanctioned.length} sanctioned — not counted by the gate)`);
  console.log('--- R1 SETTLING sites ---');
  for (const r of out.R1.filter(r => r.calleeClass === 'SETTLING')) console.log(`  ${r.cls}.${r.caller} -> @${r.callee}${r.sanctioned ? '  [sanctioned]' : ''}  ${r.at}`);
  console.log('--- R1 EFFECTFUL sites ---');
  for (const r of trunc(out.R1.filter(r => r.calleeClass === 'EFFECTFUL'), 20)) console.log(`  ${r.cls}.${r.caller} -> @${r.callee}${r.sanctioned ? '  [sanctioned]' : ''}  ${r.at}`);
  if (!FULL) console.log('  … (--full for all)');

  console.log('\n--- R1 hard-callee shortlist (distinct callees, ref profile from the R4 harvest) ---');
  const short = new Map();
  for (const r of r1hard) {
    let s = short.get(r.callee);
    if (!s) short.set(r.callee, (s = { n: 0 }));
    s.n++;
  }
  for (const [name, s] of [...short.entries()].sort((a, b) => b[1].n - a[1].n)) {
    const defs = out.allMethods.filter(r => r.name === name).map(r => r.file + ':' + r.line);
    const o = out.nameOcc.get(name) || {};
    const twin = out.allMethodNames.has('_' + name + 'NoSettle') ? ' [has NoSettle twin]' : '';
    console.log(`  ${String(s.n).padStart(3)} sites  ${name}${twin}  defs: ${defs.slice(0, 3).join(' ')}  refs[self/member/other/ext]: ${o.self || 0}/${o.member || 0}/${o.other || 0}/${o.external || 0}`);
  }

  console.log('\n=== R2: public -> public SETTLING self-call ===');
  console.log(`total: ${out.R2.length} sites (mostly the designed dispatcher pattern — NOT violations), from constructors: ${out.R2.filter(r => r.ctor).length}`);
  console.log('--- R2 NARROWED (caller directly settles too — the double-flush shape; static twin: check-layering rule [T]) ---');
  for (const r of out.R2narrowed) console.log(`  ${r.cls}.${r.caller} -> @${r.callee}${r.sanctioned ? '  [sanctioned]' : ''}  ${r.at}`);
  if (FULL) {
    console.log('--- R2 all sites ---');
    for (const r of out.R2) console.log(`  ${r.cls}.${r.caller}${r.ctor ? ' [ctor]' : ''} -> @${r.callee}  ${r.at}`);
  }

  console.log('\n=== R3: literal mixed-use (informational — not a proposed rule) ===');
  console.log(`public callers mixing: ${out.R3.public.length}, private callers mixing: ${out.R3.private.length}`);

  console.log('\n=== R4: privatization candidates (public, only ever @-self-called) ===');
  if (!out.R4) {
    console.log('SKIPPED — sibling Fizzygum-tests repo not found (R4 needs its reference set to be sound).');
  } else {
    const cmd = out.R4.filter(r => r.effectful), qry = out.R4.filter(r => !r.effectful);
    console.log(`total: ${out.R4.length}  (EFFECTFUL — rename first: ${cmd.length};  QUERY — cosmetic: ${qry.length})`);
    console.log('--- EFFECTFUL candidates ---');
    for (const r of trunc(cmd, 25)) console.log(`  ${String(r.selfCalls).padStart(4)}x  ${r.name}  (${r.defs.slice(0, 4).join(', ')}${r.defs.length > 4 ? '…' : ''})`);
    if (!FULL) console.log('  … (--full for all)');
    console.log('--- QUERY candidates ---');
    for (const r of trunc(qry, 25)) console.log(`  ${String(r.selfCalls).padStart(4)}x  ${r.name}  (${r.defs.slice(0, 4).join(', ')}${r.defs.length > 4 ? '…' : ''})`);
    if (!FULL) console.log('  … (--full for all)');
  }

  if (JSON_OUT) {
    const dump = { ...out, nameOcc: undefined, allMethods: undefined, allMethodNames: undefined,
                   classInfo: undefined, chainOf: undefined, resolve: undefined };
    fs.writeFileSync(JSON_OUT, JSON.stringify(dump, null, 1));
    console.log('\n[census] JSON written to ' + JSON_OUT);
  }
  process.exit(0);
}

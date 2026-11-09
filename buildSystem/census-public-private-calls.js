#!/usr/bin/env node
'use strict';
/*
 * census-public-private-calls.js — the public/private SELF-call census: an ANALYSIS CLI *and* the
 * measurement ENGINE behind the check-call-separation.js gate (rules [S]/[U] — see
 * docs/archive/public-private-call-separation-plan.md; gate reference: docs/architecture/lint-and-static-checks.md).
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
 *         SETTLING    — transitively reaches a settle (a settle tier — lib/settle-tiers.js — or
 *                       recalculateLayouts) through @-self calls, or member-calls a settling setter
 *                       (the geometry + text setters lib/settling-setters.js reads from Widget and
 *                       StringWdgt: setExtent/moveTo/setBounds/setWidth/setHeight, setText/setFontSize/…).
 *         EFFECTFUL   — transitively mutates state (own-field assignment [cache/memo/counter/hash
 *                       fields carved out — memoizing getters are morally queries], collection
 *                       mutation on an own field, a repaint, _invalidateLayout) but never settles.
 *                       A repaint is a call to one of the repaint verbs (`_changed`/`_fullChanged…`,
 *                       read from Widget by lib/repaint-verbs.js). Those verbs are PRIVATE, so this
 *                       census never meets one as a callee: they count as an effect of the method
 *                       that calls them, never as a public command of their own.
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
 *       tests repo's CODE is a `@`-self call. A reference is what lib/method-references.js says
 *       reaches a method (a property access, a whole-name string, a name template, a computed
 *       access on a named class); a bare word — a local, a key, prose — is none and counts
 *       nothing. So: never a `.member` access, never a reference inside a string (menu/connection
 *       dispatch is name-string-driven, and a macro heredoc is external surface), never reached by
 *       computed dispatch, never referenced by Fizzygum-tests' code — its harness, its macro
 *       sources or its scripts/ rigs, comments cut and its prose, reference records and manifests
 *       unread (lib/tests-repo-code.js). Provably not external API → candidates for
 *       a `_` rename (rule [U]; deliberate end-user API goes in buildSystem/public-api-allowlist.txt).
 *       NEEDS the sibling Fizzygum-tests repo; R4 is null (and rule [U] SKIPS) when it is absent.
 *
 * HOW (same philosophy as the check-*.js gates — a heuristic line scanner, no type inference):
 *   - Parsing machinery: every source is read through lib/coffee-mask.js (R1-R3 read each line's bare code,
 *     comments and literal contents blanked; R4 its code, literals kept); methods are grouped by the shared lib/coffee-method-header.js
 *     methodBoundary — 2-space class methods and mixin onceAddedClassProperties members.
 *   - Class = file basename (one-class-per-file); `extends` / `@augmentWith` edges regex-scanned
 *     exactly like src/boot/dependencies-finding.coffee does.
 *   - A `@name` occurrence counts as a CALL when followed by `(`, or by whitespace + a value token
 *     that is not an operator/keyword (`@foo bar` calls; `@foo if x`, bare `@foo`, `@foo = …`,
 *     `@foo.bar` do not). Markers are read from the RAW line (they live in comments).
 *   - Effect/settle classification is a fixpoint over the @-SELF call graph only. NB this is NOT
 *     the rejected [G] transitive closure (that was BACKWARD reachability including `.`-member
 *     calls and `new` constructor hubs — ~500-710 false hits, docs/architecture/lint-and-static-checks.md §7);
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
 *   … [--src=DIR] [--tests-repo=DIR]   # the rails (lib/source-files.js sourceRoots) read another src tree / tests repo
 * It reads the compiled sources (lib/source-files.js compiledFiles: src/ and the tests repo's harness).
 * The call-extractor fixtures are census-public-private-calls-selftest.js (run on every build by
 * buildSystem/run-selftests.js).
 *
 * CLI exit codes: 0 = ran (the CLI never "fails" on findings — enforcement is
 * check-call-separation.js's job), 2 = operational error.
 */

const fs = require('fs');
const path = require('path');
const { compiledFiles, sourceName, sourceRoots, SOURCE_RAILS, SRC, TESTS_REPO } = require('./lib/source-files');

// the [S] per-method conscious sign-off: a hard R1 site whose CALLER carries this marker is
// reported but NOT counted by the gate (mirror of check-layering's nosettle-sanctioned mechanics)
const PUBLIC_CALL_MARKER = 'public-call-sanctioned';
// rule [T]'s marker (owned by check-layering.js) — the census reads it too so its narrowed-R2
// report shows which double-settle shapes are consciously signed off
const DOUBLE_SETTLE_MARKER = 'double-settle-sanctioned';


// The reading of every source: R4's occurrence harvest needs its per-character mask too (strings are
// dynamic-dispatch surface and must DISQUALIFY a privatization candidate).
const { coffeeMask } = require('./lib/coffee-mask');
const { testsRepoCode } = require('./lib/tests-repo-code');
const methodRefs = require('./lib/method-references');

const { METHOD_HEADER, MIXIN_METHOD_HEADER, methodBoundary } = require('./lib/coffee-method-header');

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
// A direct settle (any settle tier, read from Widget by lib/settle-tiers.js, or the flush recalculateLayouts itself)
// and a member call to a settling setter (the geometry + text setters lib/settling-setters.js reads from Widget and
// StringWdgt — the same names check-layering's rules key on) are both built inside runCensus: each library throws
// when its family is not where it reads it, and both callers turn a runCensus throw into an operational error.
const { settleTierAlternation } = require('./lib/settle-tiers');
const { settlingSetters } = require('./lib/settling-setters');
// the canvas-context moveTo carve-out (same as check-layering rule [A]'s CANVAS_MOVETO)
const CANVAS_MOVETO = /\b(context|pctx|backBufferContext|aContext|ctx|cacheCtx|targetContext)\s*\.\s*moveTo\b/;
const FIELD_ASSIGN = /@([A-Za-z_]\w*)(\.[A-Za-z_]\w*)*\s*(\?=|\|\|=|\+=|-=|\*=|\/=|=(?![=>]))/;
// memoizing getters / cache hygiene / counters are morally queries — carve their writes out
const CACHEY = /cache|Cache|memo|Memo|_last|Counter|counter|hash|Hash/;
const COLLECTION_MUT = /@[A-Za-z_]\w*\.(push|splice|pop|shift|unshift|sort|reverse|set|delete|clear|add)\b/;
// a repaint: a call to one of the repaint verbs (_changed / _fullChanged…), READ from Widget's own
// definitions by lib/repaint-verbs.js. Built inside runCensus: the module throws when it finds the
// family gone, and both callers turn a runCensus throw into an operational error, so a renamed family
// fails this engine (and the check-call-separation gate on it) instead of silently dropping the signal.
const { repaintVerbAlternation } = require('./lib/repaint-verbs');
const SCHEDULE_CALL = /[@.]\s*_invalidateLayout\b/;

// ============================== THE ENGINE ==============================
// runCensus({ src, testsRepo }) reads the compiled sources of the trees it is given (lib/source-files.js compiledFiles:
// src and the tests repo's harness; default this umbrella's, a gate's --src= / --tests-repo= rails hand it planted
// copies), and R4 the tests repo's code besides. Returns { stats, R1, R2, R2narrowed, R3, R4, haveTestsRepo }.
//   R1 row:  { cls, caller, callee, calleeClass, sanctioned, at }
//   R2 row:  { cls, caller, ctor, callerDirectlySettles, sanctioned, callee, at }
//   R4 row:  { name, selfCalls, effectful, defs }   (R4 = null when the tests repo is absent)
function runCensus({ src = SRC, testsRepo = TESTS_REPO } = {}) {
  if (!fs.existsSync(src)) throw new Error('cannot find ' + src + ' — run from the Fizzygum repo root');
  const roots = { src, testsRepo };
  const REPAINT_CALL = new RegExp('[@.]\\s*(' + repaintVerbAlternation(src) + ')\\b');
  const SETTLE_DIRECT = new RegExp('[@.]\\s*(' + settleTierAlternation(src) + '|recalculateLayouts)\\b');
  const setters = settlingSetters(roots);
  const memberSettleRe = new RegExp('\\.\\s*(' + [...setters.geometry, ...setters.text].join('|') + ')\\b');

  // ---- phase 1: parse every compiled class ----
  const classInfo = new Map();   // name -> { name, parent, mixins[], methods: Map(name->rec), file }
  const allMethods = [];         // rec: { name, cls, file, line, bodyLines: [{n, code}], markers:Set }
  const sourceFiles = compiledFiles(roots);
  const maskedFiles = new Map();   // file -> its lib/coffee-mask.js reading, read once for phase 1 and R4
  for (const file of sourceFiles) {
    const rel = sourceName(file, roots);
    const clsName = path.basename(file, '.coffee');
    const text = fs.readFileSync(file, 'utf8');
    const lines = text.split('\n');
    const masked = coffeeMask(text, rel);
    maskedFiles.set(file, masked);
    let info = classInfo.get(clsName);
    if (!info) { info = { name: clsName, parent: null, mixins: [], methods: new Map(), file: rel }; classInfo.set(clsName, info); }
    let mixinHashIndent = null, cur = null;
    for (let n = 0; n < lines.length; n++) {
      const raw = lines[n];
      const code = masked[n].bare;
      const clsM = raw.match(/^class ([A-Za-z_]\w*)( extends ([A-Za-z_]\w*))?/);
      if (clsM && clsM[1] === clsName) info.parent = clsM[3] || null;
      const augM = code.match(/@augmentWith\s+([A-Za-z_]\w*)/);
      if (augM) info.mixins.push(augM[1]);
      if (!masked[n].continuesLiteral) {             // a line inside a heredoc holds no boundary
        const b = methodBoundary(raw, mixinHashIndent);
        if (b) {
          mixinHashIndent = b.mixinHashIndent;
          // a class-side `@name` method is no instance method: its `@` is the class, so its body holds no
          // self-call this census measures — it ENDS the method above it and is not counted itself
          if (b.kind === 'header' && b.static) { cur = null; continue; }
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
        // markers live in comments: read the line's comment
        const comment = masked[n].comment || '';
        if (comment.includes(PUBLIC_CALL_MARKER)) cur.markers.add(PUBLIC_CALL_MARKER);
        if (comment.includes(DOUBLE_SETTLE_MARKER)) cur.markers.add(DOUBLE_SETTLE_MARKER);
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
  out.stats = { files: sourceFiles.length, classes: classInfo.size, methods: allMethods.length, public: nPub, private: nPriv, leaf: nLeaf };

  for (const rec of allMethods) {
    const callerTier = tierOf(rec.name);
    const pubCalls = [], privCalls = [];
    for (const c of rec.selfCalls) {
      if (c.kind !== 'call') continue;
      (tierOf(c.callee) === 'public' ? pubCalls : privCalls).push(c);
    }
    if (callerTier !== 'public') {
      for (const c of pubCalls) {
        out.R1.push({ cls: rec.cls, caller: rec.name, callee: c.callee, calleeClass: classifyCallee(rec.cls, c.callee),
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
  // Occurrence harvest: every REFERENCE to a public method name, by the one rule (lib/method-references.js —
  // a property access, a whole-name string, a name template, a computed access on a named class), read from
  // code (comments cut by coffee-mask). A bare word — a local, a key, a def's own name — is no reference and
  // counts nothing. Outside strings: `@m` is a self-call, `.m`/`::m` a member access. INSIDE a string a
  // reference bumps 'other' REGARDLESS of its form — strings are dynamic-dispatch / macro-heredoc surface, so
  // they must DISQUALIFY a candidate (the 2026-07-12 T5 lesson: a `Macro.fromString """…"""` heredoc calling
  // `@someToolkitVerb` was classified 'self', letting a de-facto macro-surface verb into the rename list — the
  // rename then tripped rule [D]). A method computed dispatch reaches is 'other' too.
  const publicNames = new Set();
  for (const rec of allMethods) if (tierOf(rec.name) === 'public') publicNames.add(rec.name);
  const nameOcc = new Map();   // name -> {self, member, other, external}
  const bump = (name, kind) => {
    let o = nameOcc.get(name);
    if (!o) nameOcc.set(name, (o = { self: 0, member: 0, other: 0, external: 0 }));
    o[kind]++;
  };
  const templates = [], computedClasses = [];
  for (const file of sourceFiles) {
    for (const { mask, code } of maskedFiles.get(file)) {
      const r = methodRefs.methodReferences(code);
      templates.push(...r.templates);
      computedClasses.push(...r.classes);
      for (const o of r.occurrences) {
        if (!publicNames.has(o.name)) continue;
        if (o.via === 'string' || mask[o.index] === 'str') bump(o.name, 'other');   // dispatch / macro surface
        else bump(o.name, o.via === '@' ? 'self' : 'member');
      }
    }
  }
  out.nameOcc = nameOcc;
  // a tests repo that exists holds its harness (compiledFiles above refuses one that does not)
  out.haveTestsRepo = fs.existsSync(path.join(testsRepo, 'tests'));
  if (out.haveTestsRepo) {
    // The rest of the tests repo's CODE (lib/tests-repo-code.js): the macro sources and the scripts/ rigs,
    // strings kept (name dispatch) and comments cut. Its metadata prose, reference-image records and
    // manifests are not code, so a sentence naming a method never counts as a call of it. The harness is
    // a compiled source, read above with each reference classified by its receiver: read again here, a
    // harness class's own `@m` would count as EXTERNAL and no harness method could be self-only.
    for (const { kind, lines } of testsRepoCode(testsRepo)) {
      if (kind === 'harness') continue;
      for (const line of lines) {
        const r = methodRefs.methodReferences(line);
        templates.push(...r.templates);
        computedClasses.push(...r.classes);
        for (const n of r.names) if (publicNames.has(n)) bump(n, 'external');
      }
    }
    // computed dispatch from either side (a "_#{a}Connector" template, a `C::[k]` access) reaches a method by a
    // name no token spells: not a self-call, so it disqualifies like any other reference
    const instanceMethods = allMethods.map((r) => ({ name: r.name, cls: r.cls, classSide: false }));
    const chainNames = (c) => (classInfo.has(c) ? chainOf(c).map((i) => i.name) : [c]);
    for (const n of methodRefs.reachedByComputedDispatch(templates, computedClasses, instanceMethods, chainNames)) if (publicNames.has(n)) bump(n, 'other');
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

module.exports = { runCensus, PUBLIC_CALL_MARKER, DOUBLE_SETTLE_MARKER, tierOf, classifyOccurrence, METHOD_HEADER };

// ============================== THE CLI ==============================
if (require.main === module) {
  require('./lib/cli-args').rejectUnknownArgs(process.argv.slice(2), [...SOURCE_RAILS, '--full', '--json'], 'census-public-private-calls');
  const ROOTS = sourceRoots(process.argv.slice(2), 'census-public-private-calls');
  const FULL = process.argv.includes('--full');
  const jsonIdx = process.argv.indexOf('--json');
  const JSON_OUT = jsonIdx >= 0 ? process.argv[jsonIdx + 1] : null;

  let out;
  try { out = runCensus(ROOTS); }
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

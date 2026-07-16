#!/usr/bin/env node
// check-composite-relay.js — build lint: a COMPOSITE (a class whose `_reLayout` places its own
// children, or that defines `_reLayoutChildren`) must DECLARE `_placesChildrenInLayout: -> true`
// (own or inherited) so the base `Widget._applyExtent` re-lays its children when an immediate
// resize commits its frame — or carry an explicit exemption naming why its children are immune.
//
// WHY. The immediate extent path is deliberately non-notifying and self-only (_applyExtentBase:
// commit + changed + _reLayoutSelf — children are NOT re-laid, layout is NOT invalidated, and a
// freshly-built widget is settled, so nothing later heals it). A composite resized via the raw
// core with no re-lay keeps stale children PERMANENTLY — the INV-2 bug class
// (docs/done/layout-regressions-2026-07-icons-plots-editghosts-plan.md). Until 2026-07-16 the
// re-lay was an OPT-IN hand-copied `_applyExtent` override (8 copies); the 9th composite that
// needed one didn't have it (WidgetHolderWithCaptionWdgt — the oversized-Basement-icon
// regression REACHED PRODUCTION unseen; notably that arc's own hand class-audit missed the class
// too). This gate replaces remembering-to-copy with a build failure. Mirrors
// check-relayout-bounds-first.js / check-relayout-repaints.js (line scanner; exit 0 clean /
// 1 violation) — plus ONE delta: the declaration is resolved through the `extends` chain
// (WindowWdgt passes via SimpleVerticalStackPanelWdgt; the icon subclasses via
// GenericCompositeIconWdgt), the same textual `class X extends Y` edge the boot dependency
// finder keys off.
//
// THE RULE. A class file that defines `_reLayout:` or `_reLayoutChildren:` (2-space method
// header) must satisfy ONE of:
//   1. `_placesChildrenInLayout: -> true` declared on the class or an ancestor (nearest
//      declaration in the chain wins — an explicit `false` re-declaration does NOT satisfy);
//   2. a `# immediate-resize-relay-exempt: <reason>` marker (non-empty reason) in the contiguous
//      comment block directly above the `_reLayout:`/`_reLayoutChildren:` header, asserting why
//      stale children are impossible (no children placed / children placed from the param and
//      healed elsewhere / never sized via the raw immediate core / handles the forward itself).
// The trigger is DELIBERATELY over-inclusive (any `_reLayout` override, child-placing or not):
// "places children" is not reliably decidable from text, and a marker on a childless _reLayout
// is one honest comment line — cheaper than a heuristic's silent false negative shipping another
// stale-children composite to production.
//
// The base Widget (the mechanism itself) is skipped. `_placesChildrenInLayout: -> true` on a
// class with NO `_reLayout`/`_reLayoutChildren` anywhere in its chain is flagged too (a stale
// declaration — the hook would call base `_reLayout`, which is not "my composite arrangement").

const fs = require('fs');
const path = require('path');
const SRC = path.resolve(__dirname, '../src');

const HEADER  = /^  ([A-Za-z_]\w*): (\(.*?\) )?[-=]>/;                  // 2-space-indent class method header
const CLASSDECL = /^class\s+([A-Za-z_]\w*)(?:\s+extends\s+([A-Za-z_]\w*))?/m;
const EXEMPT  = /#\s*immediate-resize-relay-exempt:\s*\S/;              // marker WITH a non-empty reason

function walk(dir, acc) {
  if (!fs.existsSync(dir)) return acc;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (e.name.endsWith('.coffee')) acc.push(p);
  }
  return acc;
}

// ---- pass 1: parse every class file -------------------------------------------------------
// name -> { file, parent, declares: true|false|null (null = no declaration in this file),
//           triggers: [{name, line}], exempt: bool }
const classes = new Map();
for (const p of walk(SRC, [])) {
  const src = fs.readFileSync(p, 'utf8');
  const lines = src.split('\n');
  const decl = CLASSDECL.exec(src);
  if (!decl) continue;                                   // not a class file (boot scripts etc.)
  const name = decl[1];
  const parent = decl[2] || null;

  const info = { file: p, parent, declares: null, triggers: [], exempt: false };
  lines.forEach((l, i) => {
    const m = HEADER.exec(l);
    if (!m) return;
    if (m[1] === '_reLayout' || m[1] === '_reLayoutChildren') {
      info.triggers.push({ name: m[1], i });
      // marker: contiguous comment block directly above the header
      for (let j = i - 1; j >= 0 && /^\s*#/.test(lines[j]); j--) {
        if (EXEMPT.test(lines[j])) { info.exempt = true; break; }
      }
    }
    if (m[1] === '_placesChildrenInLayout') {
      // read the declaration's body: first non-blank, non-comment line after the header
      for (let j = i + 1; j < lines.length; j++) {
        const code = lines[j].replace(/#.*$/, '').trim();
        if (!code) continue;
        info.declares = /\btrue\b/.test(code);
        break;
      }
    }
  });
  classes.set(name, info);
}

// ---- pass 2: resolve the nearest _placesChildrenInLayout declaration up the extends chain --
function resolvedDeclaration(name, seen) {
  const info = classes.get(name);
  if (!info || (seen && seen.has(name))) return null;    // chain leaves src (Widget base libs) or cycle
  if (info.declares !== null) return info.declares;
  if (!info.parent) return null;
  (seen = seen || new Set()).add(name);
  return resolvedDeclaration(info.parent, seen);
}
// A declaration is legitimate if a trigger exists anywhere in the class's FAMILY: itself, a
// non-Widget ancestor, or any descendant (GenericCompositeIconWdgt declares for the _reLayouts
// its subclasses define). The Widget base is excluded — every chain reaches it, and its
// _reLayout is the mechanism, not a composite arrangement.
const childrenOf = new Map();
for (const [name, info] of classes) {
  if (!info.parent) continue;
  if (!childrenOf.has(info.parent)) childrenOf.set(info.parent, []);
  childrenOf.get(info.parent).push(name);
}
function familyHasTrigger(name) {
  const up = (n, seen) => {
    const info = classes.get(n);
    if (!info || n === 'Widget' || seen.has(n)) return false;
    seen.add(n);
    if (info.triggers.length) return true;
    return info.parent ? up(info.parent, seen) : false;
  };
  const down = (n, seen) => {
    if (seen.has(n)) return false;
    seen.add(n);
    for (const c of childrenOf.get(n) || []) {
      const info = classes.get(c);
      if (info && info.triggers.length) return true;
      if (down(c, seen)) return true;
    }
    return false;
  };
  return up(name, new Set()) || down(name, new Set());
}

// ---- verdicts ------------------------------------------------------------------------------
const violations = [];
let checked = 0, declared = 0, inherited = 0, exempt = 0;
for (const [name, info] of classes) {
  if (name === 'Widget') continue;                       // the base mechanism itself
  const rel = path.relative(SRC, info.file);
  if (info.triggers.length) {
    checked++;
    const resolved = resolvedDeclaration(name);
    if (resolved === true) { info.declares === true ? declared++ : inherited++; continue; }
    if (info.exempt) { exempt++; continue; }
    const at = `${rel}:${info.triggers[0].i + 1}`;
    violations.push(
      `[composite-relay] ${name} defines ${info.triggers.map(t => t.name).join(' + ')} but neither declares ` +
      `_placesChildrenInLayout: -> true (own or inherited) nor carries a ` +
      `# immediate-resize-relay-exempt: <why> marker above the header. An immediate resize ` +
      `(raw _applyExtent — ctors, _createReferenceNoSettle, arrange-time sizing) would leave its ` +
      `children at stale geometry FOREVER (the INV-2 bug class). Declare the capability if this ` +
      `class places its own children, or write the marker naming why stale children are ` +
      `impossible.  — ${at}`);
  } else if (info.declares === true && !familyHasTrigger(name)) {
    violations.push(
      `[composite-relay] ${name} declares _placesChildrenInLayout: -> true but neither it nor ` +
      `any ancestor defines _reLayout/_reLayoutChildren — a stale declaration; the immediate-` +
      `resize hook would run the non-composite base _reLayout.  — ${rel}`);
  }
}

console.log(`[composite-relay] ${checked} _reLayout/_reLayoutChildren definer(s): ` +
  `${declared} declaring + ${inherited} inheriting the declaration + ${exempt} exempt.`);
if (violations.length) {
  console.error(violations.join('\n'));
  console.error(`[composite-relay] ${violations.length} violation(s).`);
  process.exit(1);
}
console.log('[composite-relay] OK — every composite either declares the immediate-resize child re-lay or is explicitly exempt.');

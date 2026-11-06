'use strict';
// lib/settle-tiers.js — THE settle tiers: the Widget methods a mutation runs inside so the world's layout
// is flushed (`world.recalculateLayouts()`) before the call returns. Two ROLES today: the single-mutation
// tier `_settleLayoutsAfter`, which every self-settling public setter and structural wrapper uses, and the
// reactive-connection lane `_settleLayoutsAfterOrJoinEnclosingPass`, which JOINS an enclosing settle's
// mutation window instead of throwing (check-layering rule [P]). READ from Widget's own definitions, never
// spelled out, by every build tool that recognises a settle by name: census-nosettle-naming.js (which
// defs settle, and what a settle closure delegates to).
//
// WHY DERIVED. A hand-spelled tier list goes on matching the old names after a rename, and can name a tier
// nothing defines. A settle matcher that matches nothing reports nothing: every def reads as non-settling,
// and each rule built on it passes with a clean verdict.
//
// THE RULE: Widget's own instance methods named `_settleLayoutsAfter…`. A tier is DEFINED by what its
// body does, so the name is held to it both ways: every `_settleLayoutsAfter…` method flushes the world's
// layout, and every Widget method that flushes it carries the tier name. (check-layering rule [B] limits
// who may call recalculateLayouts at all; this reads only Widget, where the tiers are defined.)
//
// ⚠ VACUITY GUARD. This THROWS — and a tool calling it exits non-zero naming the cause — when a role name
// (`_settleLayoutsAfter`, `_settleLayoutsAfterOrJoinEnclosingPass`) is not defined on Widget, when a
// tier-named method does not flush, or when a flushing method is not tier-named. Each means the convention
// moved, and every rule keyed on the tiers needs a fresh look rather than a quieter list.
const fs = require('fs');
const path = require('path');
const { methodSpans } = require('./coffee-method-header');
const { stripComment } = require('./name-definitions');

const SETTLE_TIER_NAME = /^_settleLayoutsAfter\w*$/;
const SINGLE = '_settleLayoutsAfter';                          // the single-mutation tier
const JOIN = '_settleLayoutsAfterOrJoinEnclosingPass';          // the reactive-connection lane
const FLUSH_CALL = /[@.]\s*recalculateLayouts\b/;

// { single, join, all } — the two role names, and every tier, longest first (so an alternation built from
// them reads the longest name first). `srcRoot` = Fizzygum/src.
function settleTiers(srcRoot) {
  const file = path.join(srcRoot, 'basic-widgets', 'Widget.coffee');
  if (!fs.existsSync(file)) {
    throw new Error(`settle-tiers: ${file} not found — the settle tiers are read from Widget's own definitions`);
  }
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  const own = methodSpans(lines).filter((s) => !s.static && !s.mixin);
  const named = [...new Set(own.filter((s) => SETTLE_TIER_NAME.test(s.name)).map((s) => s.name))];
  const flushing = [...new Set(own
    .filter((s) => lines.slice(s.line + 1, s.end).some((l) => FLUSH_CALL.test(stripComment(l))))
    .map((s) => s.name))];
  const problems = [];
  const missing = [SINGLE, JOIN].filter((n) => !named.includes(n));
  if (missing.length) problems.push(`Widget.coffee defines no ${missing.join(' / ')}`);
  const nonFlushing = named.filter((n) => !flushing.includes(n));
  if (nonFlushing.length) problems.push(`${nonFlushing.join(' / ')} carries the tier name but does not call recalculateLayouts`);
  const unnamed = flushing.filter((n) => !named.includes(n));
  if (unnamed.length) problems.push(`${unnamed.join(' / ')} calls recalculateLayouts without the _settleLayoutsAfter… name`);
  if (problems.length) {
    throw new Error(`settle-tiers: ${problems.join('; ')}. Tier-named: [${named.join(', ') || 'none'}]; flushing: [${flushing.join(', ') || 'none'}]. `
      + 'If the tiers were renamed or a tier was added, update SETTLE_TIER_NAME / SINGLE / JOIN in buildSystem/lib/settle-tiers.js and re-read the rules that use them.');
  }
  return { single: SINGLE, join: JOIN, all: named.sort((a, b) => b.length - a.length || a.localeCompare(b)) };
}

// Every tier as a regex alternation body: `_settleLayoutsAfterOrJoinEnclosingPass|_settleLayoutsAfter`.
// (Method names are `[A-Za-z_]\w*` — lib/coffee-method-header.js — so none needs escaping.)
function settleTierAlternation(srcRoot) {
  return settleTiers(srcRoot).all.join('|');
}

module.exports = { settleTiers, settleTierAlternation };

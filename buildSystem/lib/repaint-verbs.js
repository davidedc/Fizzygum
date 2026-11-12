'use strict';
// lib/repaint-verbs.js — THE repaint verbs: the private self-invalidation family a widget marks
// itself changed through (`@_changed()` just me, `@_fullChanged()` me and my subtree, plus the
// `_fullChanged…` variants such as the shadow-aware `_fullChangedIncludingShadowOwner`). READ from
// Widget's own definitions, never spelled out, by every gate that recognises a repaint by name:
// check-layering.js (rule [I]: a `__` leaf must not repaint; rule [K]: a notify-only corner must not
// react) and census-public-private-calls.js (a repaint is an EFFECT, which makes its caller a command).
//
// WHY DERIVED. A hand-spelled verb list keeps matching the old names after a rename of the family, and a
// matcher that matches nothing reports nothing: the rule built on it goes vacuous with a clean verdict.
// Reading the names from the definitions makes a rename move every rule with it.
//
// THE RULE: Widget's own instance methods named `_changed` or `_fullChanged…`. Widget is where the
// family is defined (an override elsewhere — StringWdgt's `_changed`, the world's pair — reuses a name
// already found here, so reading subclasses would add nothing).
//
// ⚠ VACUITY GUARD. A derivation that finds nothing would make every rule built on it pass in silence,
// so both base verbs, `_changed` and `_fullChanged`, must be found or this THROWS — a gate calling it
// then exits non-zero naming the cause. Losing either one means the convention moved, and every rule
// keyed on the verbs needs a fresh look rather than a quieter list.
const fs = require('fs');
const path = require('path');
const { methodSpans } = require('./coffee-method-header');

const REPAINT_VERB_NAME = /^_(changed|fullChanged\w*)$/;
// hand-list-sanctioned: repaint-verbs.js throws on a name here Widget.coffee no longer defines, and
// check-layering.js and check-invalidation-receivers.js exit 2 on that throw
const REQUIRED = ['_changed', '_fullChanged'];

// The repaint verbs, longest first (so an alternation built from them reads the longest name first).
// `srcRoot` = Fizzygum/src.
function repaintVerbs(srcRoot) {
  const file = path.join(srcRoot, 'basic-widgets', 'Widget.coffee');
  if (!fs.existsSync(file)) {
    throw new Error(`repaint-verbs: ${file} not found — the repaint verbs are read from Widget's own definitions`);
  }
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  const verbs = [...new Set(methodSpans(lines)
    .filter((s) => !s.static && REPAINT_VERB_NAME.test(s.name))
    .map((s) => s.name))];
  const missing = REQUIRED.filter((n) => !verbs.includes(n));
  if (missing.length) {
    throw new Error(`repaint-verbs: Widget.coffee defines no ${missing.join(' / ')} — the self-invalidation family the repaint rules key on is not where they read it, so they would miss ${missing.length === REQUIRED.length ? 'every repaint' : 'part of it'}. `
      + `Found: [${verbs.join(', ') || 'none'}]. If the family was renamed, update REPAINT_VERB_NAME / REQUIRED in buildSystem/lib/repaint-verbs.js and re-read the rules that use it.`);
  }
  return verbs.sort((a, b) => b.length - a.length || a.localeCompare(b));
}

// The verbs as a regex alternation body: `_fullChangedIncludingShadowOwner|_fullChanged|_changed`.
// (Method names are `[A-Za-z_]\w*` — lib/coffee-method-header.js — so none needs escaping.)
function repaintVerbAlternation(srcRoot) {
  return repaintVerbs(srcRoot).join('|');
}

module.exports = { repaintVerbs, repaintVerbAlternation };

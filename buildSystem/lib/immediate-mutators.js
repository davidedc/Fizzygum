'use strict';
// lib/immediate-mutators.js — THE immediate geometry mutators: the methods that write a widget's frame in
// place, at once, and never settle — so they carry no NoSettle suffix (census-nosettle-naming.js's
// `immediate-mutator` family) — in the NAMED groups of the apply 2x2
// (docs/architecture/layering-naming-convention.md §2):
//   polymorphicApplies  `_apply<Geom>`       the polymorphic apply corners, the override DISPATCH point; they
//                                            react (repaint, re-fit in place). `_applyGrantedBounds`, the arrange
//                                            engine's frame-commit, is one of them: it repaints and applies its
//                                            extent polymorphically (the tier-naming audit's runtime `notify`
//                                            family, Fizzygum-tests/scripts/tier-naming-audit/tier-naming-prelude.js,
//                                            holds it with the other `_apply<Geom>` corners).
//   bypassTwins         `_apply<Geom>Base`   the override-BYPASS twins the top-down arrange uses for leaf children
//   commitCorners       `_commitBounds`      the silent commit corner: no repaint, no self-relayout (that audit's
//                                            `leaf` family)
//   conveniences        `_move*` `_set*` `_resize*`   the movers, setters and resizer built on the corners
// Readers: check-layering.js — `isImmediateMutator` (rule [E]'s subject: polymorphicApplies + conveniences) and
// `APPLY_CORNER` (rule [K]'s subject: polymorphicApplies + bypassTwins + commitCorners) — and
// census-nosettle-naming.js (every group: its `immediate-mutator` family).
//
// ASSERTED, both ways: the groups are a stated table held to src. Every entry must name an instance method
// defined in src — an entry naming nothing is a group that moved, and a rule keyed on it checks less with a
// clean verdict. And every Widget-own `_apply*` / `_commit*` method (the corner SHAPE; Widget is where the
// corners are defined — a subclass overrides one, it does not introduce one) must be claimed by a group or
// listed in NOT_CORNERS with what it is instead; a NOT_CORNERS entry that is no Widget method, or that a group
// also claims, is stale. Any of these THROWS, and a caller exits 2 naming it: the table is the tool's own
// definition, so a stale one is an operational fault, not a finding about src.
const fs = require('fs');
const path = require('path');
const { methodSpans } = require('./coffee-method-header');

const GROUPS = {
  // hand-list-sanctioned: immediateMutators() throws STALE_ALLOWLIST_ENTRY on an entry naming no src method, and on a Widget corner no group claims — check-layering.js and census-nosettle-naming.js exit 2
  polymorphicApplies: ['_applyExtent', '_applyBounds', '_applyGrantedBounds', '_applyWidth', '_applyHeight', '_applyMoveBy', '_applyMoveTo'],
  // hand-list-sanctioned: immediateMutators() throws STALE_ALLOWLIST_ENTRY on an entry naming no src method — check-layering.js and census-nosettle-naming.js exit 2
  bypassTwins:        ['_applyExtentBase', '_applyMoveByBase', '_applyMoveToBase'],
  commitCorners:      ['_commitBounds'],
  // hand-list-sanctioned: immediateMutators() throws STALE_ALLOWLIST_ENTRY on an entry naming no src method — check-layering.js and census-nosettle-naming.js exit 2
  conveniences:       ['_moveLeftSideTo', '_moveRightSideTo', '_moveBottomSideTo', '_moveToSideOf', '_moveFullCenterTo', '_moveWithin',
                       '_moveInDesktopToFractionalPosition', '_setWidthSizeHeightAccordingly', '_resizeToWithoutSpacing'],
};

// Widget-own `_apply*` / `_commit*` methods that are NOT geometry corners, name -> what it is instead.
const NOT_CORNERS = {
  _applyTransformSugarNoSettle: 'a *NoSettle core: a rotate/scale sugar change materialised on the enclosing island (a transform spec, not a frame)',
};
const CORNER_SHAPE = /^_(apply|commit)[A-Z]/;

function walk(dir, acc) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (e.name.endsWith('.coffee')) acc.push(p);
  }
  return acc;
}

// { polymorphicApplies, bypassTwins, commitCorners, conveniences, all } — each an array of method names, `all`
// every group's names. `srcRoot` = Fizzygum/src.
function immediateMutators(srcRoot) {
  const widgetFile = path.join(srcRoot, 'basic-widgets', 'Widget.coffee');
  if (!fs.existsSync(widgetFile)) {
    throw new Error(`immediate-mutators: ${widgetFile} not found — the corner shapes are held against Widget's own definitions`);
  }
  const defined = new Set();
  let widgetOwn = [];
  for (const file of walk(srcRoot, [])) {
    const own = methodSpans(fs.readFileSync(file, 'utf8').split('\n')).filter((s) => !s.static).map((s) => s.name);
    for (const n of own) defined.add(n);
    if (file === widgetFile) widgetOwn = own;
  }
  const claimed = new Map();   // name -> group
  for (const [group, names] of Object.entries(GROUPS)) for (const n of names) claimed.set(n, group);
  const problems = [];
  for (const [n, group] of claimed) {
    if (!defined.has(n)) problems.push(`STALE_ALLOWLIST_ENTRY ${group}: ${n} names no method defined in src`);
  }
  for (const n of Object.keys(NOT_CORNERS)) {
    if (!widgetOwn.includes(n)) problems.push(`STALE_ALLOWLIST_ENTRY NOT_CORNERS: ${n} is not a Widget method`);
    else if (claimed.has(n)) problems.push(`STALE_ALLOWLIST_ENTRY NOT_CORNERS: ${n} is also claimed by ${claimed.get(n)} — a name is a corner or it is not`);
  }
  for (const n of new Set(widgetOwn)) {
    if (CORNER_SHAPE.test(n) && !claimed.has(n) && !(n in NOT_CORNERS)) {
      problems.push(`Widget.${n} has a geometry-corner shape but no group claims it — add it to its group in GROUPS, or to NOT_CORNERS with what it is instead`);
    }
  }
  if (problems.length) {
    throw new Error(`immediate-mutators: ${problems.length} stale name(s) in buildSystem/lib/immediate-mutators.js — ${problems.join('; ')}`);
  }
  const out = {};
  for (const [group, names] of Object.entries(GROUPS)) out[group] = [...names];
  out.all = [...claimed.keys()];
  return out;
}

module.exports = { immediateMutators };

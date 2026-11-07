#!/usr/bin/env node
'use strict';
// census-call-arity.js — QUERY the call sites of both repos, each with its real argument count: the work-list tool for
// converting a family (which `new X` sites, which `super`s, which calls of a method — and how many arguments each
// passes). ADVISORY: nothing gates on it. The VERDICT on those sites — which `undefined` is a hole, with its witness —
// is check-argument-holes.js's alone (`--values` lists the ones it judges values); both read ONE table,
// lib/call-sites.js, so the two can never disagree about what a call is.
//
// The table is read by real parsers (lib/call-sites.js's header: the browser's own CoffeeScript 2.0.3 over every
// class fragment as the meta-compiler splits and rewrites it, every mixin, every macro source and the MacroToolkit
// heredocs; acorn over the tests repo's scripts), so an implicit object `face: x, toolTip: y` is ONE argument, a
// nested paren-less call is one argument of the outer call, and a string's contents are never a call.
//
// Usage (from Fizzygum/):
//   node buildSystem/census-call-arity.js StringWdgt TextWdgt [--min=3]   # `new X` sites
//   node buildSystem/census-call-arity.js --super=ButtonWdgt,LabelButtonWdgt   # the `super` calls IN those classes
//   node buildSystem/census-call-arity.js --call=add,addMenuItem [--min=4]     # calls of those METHOD names
// Each row: `<argument count>  <file>:<line>  <callee>  [ <arguments> ]`, most arguments first; then the total and
// the arity histogram. A source the reader cannot parse is named on stderr.

const path = require('path');
const { callSites, describeCallee } = require('./lib/call-sites');

const ROOT = path.resolve(__dirname, '..', '..');
const ARGV = process.argv.slice(2);
for (const a of ARGV) {
  if (a.startsWith('--') && !/^--(min|super|call)=/.test(a)) {
    console.error(`census-call-arity: unknown flag ${a}` + (a === '--holes' ? ' — the hole verdict is check-argument-holes.js\'s (run it; --values lists the values)' : ''));
    process.exit(2);
  }
}
const flag = (name) => (ARGV.find((a) => a.startsWith(name + '=')) || '').slice(name.length + 1);
const minArgs = Number(flag('--min') || 0);
const superOf = flag('--super').split(',').filter(Boolean);
const callOf = flag('--call').split(',').filter(Boolean);
const classes = ARGV.filter((a) => !a.startsWith('--'));
if (!classes.length && !superOf.length && !callOf.length) {
  console.error('census-call-arity: name the classes (`new` sites), --super=<classes> or --call=<methods>');
  process.exit(2);
}

const { sites, unreadable } = callSites({ srcDir: path.join(ROOT, 'Fizzygum', 'src'), testsRepoDir: path.join(ROOT, 'Fizzygum-tests') });
for (const u of unreadable) console.error(`UNREADABLE ${path.relative(ROOT, u.file)}${u.line ? ':' + u.line : ''} — ${u.message}`);

const rows = sites.filter((s) =>
  (classes.length && s.kind === 'new' && classes.includes(s.name)) ||
  (superOf.length && s.kind === 'super' && superOf.includes(s.superOf)) ||
  (callOf.length && (s.kind === 'send' || s.kind === 'bare') && callOf.includes(s.name)));
const arity = (s) => (s.forwarding ? -1 : s.args.length);   // a forwarding super's arity is its caller's: listed last
rows.sort((x, y) => arity(y) - arity(x) || x.file.localeCompare(y.file) || x.line - y.line);
const shown = rows.filter((s) => s.args.length >= minArgs);
for (const s of shown) {
  const args = s.forwarding ? 'forwards its caller\'s arguments' : s.args.map((a) => a.text).join(' | ');
  console.log(`${s.forwarding ? '?' : s.args.length}  ${path.relative(ROOT, s.file)}:${s.line}  ${describeCallee(s)}  [ ${args} ]`);
}
const hist = {};
for (const s of rows) { const k = s.forwarding ? '?' : s.args.length; hist[k] = (hist[k] || 0) + 1; }
console.log(`\nTOTAL ${rows.length} site(s); shown ${shown.length} (>=${minArgs} args). Arity histogram:`,
  Object.keys(hist).sort((a, b) => a - b).map((k) => `${k}:${hist[k]}`).join('  '));

#!/usr/bin/env node
// compile-fragment.js — compile a CoffeeScript fragment THE WAY THE BROWSER DOES, and print the JS.
//
// WHY THIS EXISTS: `coffee -bcp <wholefile>` is NOT a faithful answer to "what does this method
// actually compile to". The browser never compiles a whole class file — src/meta/Class.coffee
// splits each class into per-field fragments, rewrites every `super` form into a plain
// `__super__` call, and compiles each fragment with {bare:true}. A whole-file compile instead
// uses ES class semantics (parameters bound AFTER super, bare `super` illegal as a statement) and
// false-fails on most files in this tree.
//
// Use it to check a call/`super` spelling BEFORE converting a family — in particular that a
// trailing `key: value` lands as a SEPARATE final argument rather than folding into the
// positionals. That check is a standing hazard of the constructor-conformance arc
// (docs/plans/constructor-parameter-conformance-plan.md §8) and this is the tool for it.
//
// Usage: node buildSystem/compile-fragment.js <file.coffee>        # that file's constructor
//        node buildSystem/compile-fragment.js --stdin [ClassName]  # a fragment on stdin
//
// e.g.  printf 'add: (aWdgt, opts = {}) ->\n  super aWdgt, opts\n' \
//         | node buildSystem/compile-fragment.js --stdin ScrollPanelWdgt
//
// ⚠ The super rewrite below is TRANSCRIBED from Class.coffee's _equivalentforSuper, not shared
// with it — this tool compiles ONE pasted fragment, while check-coffee-syntax.js drives whole
// shipped sources through the real Class.coffee. If the meta-compiler's rewrite ever changes,
// change it here too; Class.coffee is the source of truth.

const fs = require('fs');
const path = require('path');
const REPO = path.resolve(__dirname, '..');
const COMPILER = path.join(REPO, 'auxiliary files', 'CoffeeScript', 'fizzygum-coffeescript-min.js');
const mod = require(COMPILER);
const CoffeeScript = (mod && mod.CoffeeScript) || mod;

function rewriteSuper(src, className, fieldName = 'constructor') {
  const superBase = className + '.__super__.' + fieldName;
  let s = src;
  s = s.replace(/super\(\)/g, superBase + '.call(this)');
  s = s.replace(/super[ \t]*(#[^\n]*)?$/gm, (m, c) => superBase + '.apply(this, arguments)' + (c ? '  ' + c : ''));
  s = s.replace(/super\(/g, superBase + '.call(this, ');
  s = s.replace(/super /g, superBase + '.call this, ');
  return s;
}

// Pull the `constructor:` fragment out of a class file: from the `constructor:` line to the last
// line indented deeper than it (the same shape Class.coffee's field splitter produces).
function extractConstructor(text) {
  const lines = text.split('\n');
  const start = lines.findIndex(l => /^\s*constructor:/.test(l));
  if (start < 0) throw new Error('no constructor: line');
  const indent = lines[start].match(/^\s*/)[0].length;
  let end = start;
  for (let i = start + 1; i < lines.length; i++) {
    if (lines[i].trim() === '') { end = i; continue; }
    if (lines[i].match(/^\s*/)[0].length > indent) end = i; else break;
  }
  return lines.slice(start, end + 1).map(l => l.slice(indent)).join('\n');
}

const arg = process.argv[2];
let frag, className;
if (arg === '--stdin') {
  frag = fs.readFileSync(0, 'utf8');
  className = process.argv[3] || 'Klass';
} else {
  const text = fs.readFileSync(arg, 'utf8');
  className = path.basename(arg, '.coffee');
  frag = extractConstructor(text);
}
const rewritten = rewriteSuper(frag, className);
console.log('/* ---- fragment after the super rewrite ---- */');
console.log(rewritten.split('\n').map(l => '// ' + l).join('\n'));
console.log('/* ---- compiled ---- */');
console.log(CoffeeScript.compile(rewritten, { bare: true }));

// jsinspect-compact-report.js — condense jsinspect's JSON output into the token-efficient
// LLM-handoff list written by find_similar_code.sh (jsinspect-report.ai.txt). One line per
// structural match:
//
//   2x  src/A.coffee @methodName(jsL10-30) ~ src/B.coffee @otherName(jsL40-60)
//
// Paths are mapped back from the flattened js-mirror names (dir__Class.js ->
// src/dir/Class.coffee); "@name" is the method/function name recovered from the matched
// code's first line (blank when anonymous); "jsL" ranges are COMPILED-JS mirror lines, not
// .coffee lines — locate the code by file + method name, not by line number.
//
// Usage:  node buildSystem/jsinspect-compact-report.js <jsinspect-report.json> [mirrorDir] [coffeePrefix]
//
// Without mirrorDir every instance path is assumed to be a src/ mirror file (the original
// behaviour). With mirrorDir + coffeePrefix, only paths under mirrorDir are unflattened
// (to coffeePrefix + dir/Class.coffee, `jsL` lines); other paths are printed as-is with
// REAL `L` line numbers — that's the --tests mode, where node scripts are scanned directly.

'use strict';

const fs = require('fs');

const jsonPath = process.argv[2];
const mirrorDir = process.argv[3];
const coffeePrefix = process.argv[4] || '';
if (!jsonPath) {
  console.error('usage: node buildSystem/jsinspect-compact-report.js <jsinspect-report.json> [mirrorDir] [coffeePrefix]');
  process.exit(2);
}
const matches = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

const unflatten = (p, prefix) =>
  prefix + p.split('/').pop().replace(/\.js$/, '').replace(/__/g, '/') + '.coffee';

// -> { path, label } : mirror files get unflattened coffee paths + 'jsL', real files keep both
const locate = (p) => {
  const norm = p.replace(/^\.\//, '');
  if (!mirrorDir) return { path: unflatten(norm, 'src/'), label: 'jsL' };
  if (norm.includes(mirrorDir.replace(/^\.\//, ''))) return { path: unflatten(norm, coffeePrefix), label: 'jsL' };
  return { path: norm, label: 'L' };
};

// Best-effort name of the matched code block, from its first line.
const blockName = (code) => {
  const first = (code || '').split('\n', 1)[0];
  const m = first.match(/(\w+)\.prototype\.(\w+)\s*=/) // instance method
    || first.match(/(\w+)\.(\w+)\s*=\s*function/)      // class-side / plain assignment
    || first.match(/function\s+(\w+)/)                 // named function
    || first.match(/(\w+)\s*=\s*function/);            // var assignment
  return m ? '@' + m[m.length - 1] : '';
};

const lines = matches
  .map((mt) => ({
    n: mt.instances.length,
    span: mt.instances.reduce((s, i) => s + (i.lines[1] - i.lines[0]), 0),
    text: mt.instances
      .map((i) => {
        const loc = locate(i.path);
        return `${loc.path} ${blockName(i.code)}(${loc.label}${i.lines[0]}-${i.lines[1]})`;
      })
      .join(' ~ '),
  }))
  .sort((a, b) => b.n - a.n || b.span - a.span)
  .map((mt) => `${mt.n}x ${mt.text}`);

console.log('Structural matches (jsinspect on the compiled-JS mirror):');
console.log(lines.join('\n'));
console.log(`---\n${matches.length} structural matches`);
